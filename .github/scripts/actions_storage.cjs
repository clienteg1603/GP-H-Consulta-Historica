'use strict';

// Only disposable build outputs reviewed on 2026-11-26. Unknown names are preserved.
const RULES = {
  'GP-H-Central-Historica': [/^GP-H_Consulta_Historica_Android_debug$/, /^GP-H_Consulta_Historica_v[\d.]+_Windows_TESTE$/],
  'Central-de-Trabalho-CB5': [/^central-preventive-review-/],
  'Planilhador-de-Equipamentos': [],
  'GP-H-Consulta-Historica': [/^GP-H_Consulta_Historica_Android_release$/],
  'cacheta-app': [/^Cacheta-.*-TESTE$/],
  'Gestor-de-Equipamentos': [/^Gestor_Equipamentos_v[\d.]+_DESENVOLVIMENTO$/, /^Gestor_Equipamentos_ADMIN$/],
  'Gestor-de-Equipamentos-Releases': [],
  'CQR-Novo': [/^manager-visual$/, /^NEXO-(biometria-opcional|cadastro-contrato)-[a-f0-9]+$/],
};

function ageMs(value, now) {
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? now - parsed : -1;
}

async function maintain({github, context, core, now = Date.now()}) {
  const scope = {...context.repo};
  const rules = RULES[scope.repo];
  if (!rules) throw new Error('Repository has no reviewed storage policy');
  const artifacts = await github.paginate(github.rest.actions.listArtifactsForRepo, {...scope, per_page: 100});
  const caches = await github.paginate(github.rest.actions.getActionsCacheList, {...scope, per_page: 100});
  const active = [];
  for (const status of ['in_progress', 'queued', 'waiting', 'pending', 'requested']) {
    active.push(...await github.paginate(github.rest.actions.listWorkflowRunsForRepo, {...scope, status, per_page: 100}));
  }
  const runCache = new Map();
  const removed = [], removedCaches = [], preserved = [];
  const snapshot = a => ({id:a.id,name:a.name,bytes:a.size_in_bytes,run:a.workflow_run?.id});
  let androidManifest;
  async function androidIsPublished(artifact) {
    if (active.some(r => r.name === 'Android publish download' || r.name === 'Android release online')) return false;
    if (!androidManifest) {
      const {data:file} = await github.rest.repos.getContent({...scope, path:'latest.json', ref:'android-release'});
      androidManifest = JSON.parse(Buffer.from(file.content, 'base64').toString('utf8'));
      const match = /^https:\/\/github\.com\/clienteg1603\/GP-H-Consulta-Historica\/releases\/download\/([^/]+)\/(.+)$/.exec(androidManifest.url || '');
      if (!match) throw new Error('Android manifest does not point to a published Release');
      const {data:release} = await github.rest.repos.getReleaseByTag({...scope, tag:match[1]});
      const asset = release.assets.find(a => a.name === decodeURIComponent(match[2]) && a.state === 'uploaded');
      if (release.draft || !asset || asset.size !== androidManifest.size || asset.digest !== 'sha256:' + androidManifest.sha256) {
        throw new Error('Android Release does not match its update manifest');
      }
    }
    const {data:source} = await github.rest.repos.getContent({...scope, path:'android_app/pubspec.yaml', ref:artifact.workflow_run.head_sha});
    const version = /^version:\s*[^\n+]+\+(\d+)\s*$/m.exec(Buffer.from(source.content, 'base64').toString('utf8'));
    return Boolean(version && Number(version[1]) <= Number(androidManifest.build));
  }
  for (const artifact of artifacts) {
    if (artifact.expired) continue;
    const days = artifact.name === 'Gestor_Equipamentos_ADMIN' ? 7 : 1;
    let reason;
    if (!rules.some(rule => rule.test(artifact.name))) reason = 'unknown artifact; preserved for review';
    else if (ageMs(artifact.created_at, now) < days * 86400000) reason = 'within retention';
    else {
      const run_id = artifact.workflow_run?.id;
      if (!run_id) reason = 'source run unavailable';
      else {
        if (!runCache.has(run_id)) runCache.set(run_id, (await github.rest.actions.getWorkflowRun({...scope, run_id})).data);
        if (runCache.get(run_id).status !== 'completed') reason = 'source run still active';
        else if (scope.repo === 'GP-H-Consulta-Historica' && !(await androidIsPublished(artifact))) reason = 'Android publication pending or newer than published build';
      }
    }
    if (reason) {
      preserved.push({...snapshot(artifact),reason});
      if (reason.startsWith('unknown')) core.warning(artifact.name + ': ' + reason);
      continue;
    }
    // Recheck immediately before deletion; never delete a Release, a run, a branch or a runner.
    const {data:current} = await github.rest.actions.getArtifact({...scope, artifact_id:artifact.id});
    if (current.expired || current.created_at !== artifact.created_at || current.workflow_run?.id !== artifact.workflow_run?.id) {
      preserved.push({...snapshot(artifact),reason:'artifact changed during inventory'});
      continue;
    }
    await github.rest.actions.deleteArtifact({...scope, artifact_id:artifact.id});
    removed.push(snapshot(artifact));
    console.log('REMOVED_ARTIFACT=' + JSON.stringify(snapshot(artifact)));
  }
  // Caches are rebuildable; keep recently used entries and never evict during active builds.
  if (!active.some(r => r.id !== context.runId)) {
    for (const cache of caches) {
      if (ageMs(cache.last_accessed_at, now) < 7 * 86400000) continue;
      const recheck = await github.paginate(github.rest.actions.getActionsCacheList, {...scope, key:cache.key, per_page:100});
      const current = recheck.find(c => c.id === cache.id);
      if (!current || ageMs(current.last_accessed_at, now) < 7 * 86400000) continue;
      await github.rest.actions.deleteActionsCacheById({...scope, cache_id:cache.id});
      removedCaches.push({id:cache.id,key:cache.key,bytes:cache.size_in_bytes});
    }
  }
  const remaining = await github.paginate(github.rest.actions.listArtifactsForRepo, {...scope, per_page:100});
  const cacheAfter = await github.paginate(github.rest.actions.getActionsCacheList, {...scope, per_page:100});
  const total = items => items.reduce((n,a)=>n+(a.size_in_bytes || a.bytes || 0),0);
  const report = {repo:scope.repo,at:new Date(now).toISOString(),before:{artifacts:artifacts.filter(a=>!a.expired).length,artifact_bytes:total(artifacts.filter(a=>!a.expired)),caches:caches.length,cache_bytes:total(caches)},removed,removedCaches,preserved,after:{artifacts:remaining.filter(a=>!a.expired).length,artifact_bytes:total(remaining.filter(a=>!a.expired)),caches:cacheAfter.length,cache_bytes:total(cacheAfter)}};
  console.log('STORAGE_CLEANUP_JSON=' + JSON.stringify(report));
  await core.summary.addHeading('Actions storage maintenance').addTable([
    [{data:'Storage',header:true},{data:'Before (bytes)',header:true},{data:'Removed (bytes)',header:true},{data:'After (bytes)',header:true}],
    ['Artifacts',String(report.before.artifact_bytes),String(total(removed)),String(report.after.artifact_bytes)],
    ['Caches',String(report.before.cache_bytes),String(total(removedCaches)),String(report.after.cache_bytes)]
  ]).addRaw('\nReleases, source, update manifests, runners and secrets are outside the deletion policy.\n').write();
  return report;
}

module.exports = {maintain};
