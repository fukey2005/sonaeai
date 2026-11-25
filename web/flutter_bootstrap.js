{{flutter_js}}
{{flutter_build_config}}
// A reload must use this release's entry point, even on a basic local server.
(async () => {
  try {
    const response = await fetch('version.json', {cache: 'no-store'});
    if (response.ok) {
      const {version, build_number} = await response.json();
      if (version && build_number) {
        const revision = encodeURIComponent(
          [version, build_number, response.headers.get('last-modified')].join('-')
        );
        for (const build of _flutter.buildConfig.builds) {
          if (build.mainJsPath) build.mainJsPath += `?v=${revision}`;
        }
      }
    }
  } catch {
    // Development previews may not provide release metadata.
  }
  await _flutter.loader.load({
    config: {canvasKitBaseUrl: 'canvaskit/'},
    onEntrypointLoaded: async function(engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine();
      document.getElementById('loading')?.remove();
      await appRunner.runApp();
    }
  });
})();
