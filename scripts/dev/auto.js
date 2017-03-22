
"use strict";

const spawn = require('child_process').spawn;
const spawnSync = require('child_process').spawnSync;

const fs = require('fs');
const path = require('path');

let runTable = [];

let osumoChangeReaction;
const onOsumoChange = (e, name) => {
  if (osumoChangeReaction) {
    clearTimeout(osumoChangeReaction);
  }

  osumoChangeReaction = setTimeout(() => {
    run('sync-osumo', [
        'bash', '-c', [
          'set -x', 'source scripts/env', 'girder-install plugin -f ./osumo &',
          'echo $!', 'wait'
        ].join('\n')
    ], restartWeb);
  }, 1000);
};

let sumoIOChangeReaction;
const onSumoIOChange = (e, name) => {
  if (sumoIOChangeReaction) {
    clearTimeout(sumoIOChangeReaction);
  }

  sumoIOChangeReaction = setTimeout(() => {
    run('sync-sumo-io', [
      'rsync', '-avz', '--exclude', '.git', '--exclude', 'node_modules',
      './sumo_io/', './girder_worker/girder_worker/plugins/sumo_io'
    ], restartWorker);
  }, 1000);
};

let restartWebReaction;
const restartWeb = () => {
  if (restartWebReaction) {
    clearTimeout(restartWebReaction);
  }

  restartWebReaction = setTimeout(() => {
    nuke(
      serverPid,
      'SIGTERM',
      () => setTimeout(
        () => run(
          'server', [
            'bash', '-c', [
              'set -x', 'source scripts/env',
              'girder-server &', 'echo $!', 'wait'
            ].join('\n')
          ], ()=>{}
        ).stdout.once('data', (data) => {
          serverPid = Number.parseInt(data.toString());
        }),

        10000
      )
    );
  }, 10000);
};

let restartWorkerReaction;
const restartWorker = () => {
  if (restartWorkerReaction) {
    clearTimeout(restartWorkerReaction);
  }

  restartWorkerReaction = setTimeout(() => {
    nuke(workerPid, 'SIGTERM', () => run(
      'worker', [
        'bash', '-c', [
          'set -x', 'source scripts/env', 'girder-worker &', 'echo $!', 'wait'
        ].join('\n')
      ], ()=>{}
    ).stdout.once('data', (data) => {
      workerPid = Number.parseInt(data.toString());
    }));
  }, 5000);
};

const onCloseAndExit = function (callback) {
  let result = function () { return callback.apply(this, arguments); };
  let closed = false;
  let exited = false;

  result.onClose = function () {
    closed = true;
    if (exited) {
      return result.apply(this, arguments);
    }
  };

  result.onExit = function () {
    exited = true;
    if (closed) {
      return result.apply(this, arguments);
    }
  };

  return result;
};

const onRemoveCallback = (entry, callback) => () => {
  let found = false;
  runTable = runTable.filter((e) => {
    if (found) { return true; }
    found = (e.key === entry.key);
    return !found;
  });
  if (quitTriggered) {
    if (runTable.length === 0) {
      process.exit(0);
    }
  } else {
    callback();
  }
};

const BRIGHTNESS_FACTOR = 0.25;

const onDataCallback = (entry) => () => {
  let brightness = entry.brightness;
  if (brightness < 1) { brightness = 1; }

  brightness *= Math.exp(
    (entry.time - Date.now())/(1000*(1 + BRIGHTNESS_FACTOR)));

  if (brightness < 1) { brightness = 1; }
  entry.time = Date.now();
  entry.brightness = brightness*(1 + BRIGHTNESS_FACTOR);

  if (entry.brightness > 256) { entry.brightness = 256; }
};

let quitTriggered = false;
const run = (key, command, callback) => {
  if (quitTriggered) { return; }

  try { fs.mkdirSync('cache'); } catch(e) {}
  try { fs.mkdirSync(path.join('cache', 'logs')); } catch(e) {}
  try { fs.mkdirSync(path.join('cache', 'db')); } catch(e) {}

  const stdoutFilename = path.join('cache', 'logs', [key, 'log'].join('.'));
  const stdoutStream = fs.createWriteStream(stdoutFilename);

  // const proc = spawn(command[0], command.slice(1), { detached: true });
  const proc = spawn(command[0], command.slice(1));
  let entry = { key, brightness: 1, time: Date.now(), process: proc };
  runTable.push(entry);

  const dataCallback = onDataCallback(entry);
  const removeCallback = onCloseAndExit(onRemoveCallback(entry, callback));

  proc.stdout.pipe(stdoutStream);
  proc.stderr.pipe(stdoutStream);

  proc.stdout.on('data', dataCallback);
  proc.stderr.on('data', dataCallback);
  proc.on('close', removeCallback.onClose);
  proc.on('exit', removeCallback.onExit);

  return proc;
};

let blessed;

try {
  blessed = require('blessed');
} catch(e) {
  process.chdir(path.join('scripts', 'dev'));
  spawnSync('npm', ['install', 'blessed', 'tree-kill', 'node-watch']);
  process.chdir(path.join('..', '..'));
  let status = spawnSync(
    process.argv[0],
    process.argv.slice(1),
    { stdio: 'inherit' }
  ).status;
  process.exit(status);
}

let nuke = require('tree-kill');
let watch = require('node-watch');

let screen = blessed.screen({ smartCSR: true });
screen.title = 'OSUMO Dev Environment Script';

let box = blessed.box({
  top: 0,
  left: 0,
  width: '100%',
  height: '100%',
  content: '',
  tags: true,
  border: { type: 'line' }
});

screen.append(box);

const render = () => {
  let content = runTable.map(({ key, brightness, time }) => {
    if (brightness < 1) { brightness = 1; }

    brightness *= Math.exp(
      (time - Date.now())/(1000*(1 + BRIGHTNESS_FACTOR)));

    if (brightness < 1) { brightness = 1; }

    let n = Math.floor(Math.min(10*(brightness - 1), 30));
    if (key.length >= 20) { key = key.slice(0, 19); }
    while (key.length < 20) { key = key.concat(' '); }
    for (;n--;) { key = key.concat('*'); }
    return key;
  }).join('\n');

  box.setContent(content);
  screen.render();
};

let serverPid;
let workerPid;
let watchCorePid;
let watchSumoPid;

const tryQuit = () => {
  if (quitTriggered) { return; }
  quitTriggered = true;

  (
    runTable
      .filter(({ watcher }) => watcher)
      .forEach(({ watcher }) => {
        watcher.close();
      })
  );

  runTable = runTable.filter(({ watcher }) => !watcher);


  let n = 4;
  (
    [
      serverPid,
      workerPid,
      watchCorePid,
      watchSumoPid
    ]
      .filter((pid) => pid)
      .forEach((pid) => nuke(pid, 'SIGTERM', (e) => {
        if (e) {
          console.log('ERROR!');
          console.log(e);
        }
        --n;
        if (n === 0) {
          setTimeout(quitDb, 1000);
        }
      }))
  );
};

const quitDb = () => {
  if (runTable.length) {
    (
      runTable
        .filter(({ key }) => key === 'mongod')
        .forEach(
          ({ process: proc }) => {
            if (proc && proc.pid) {
              nuke(proc.pid)
            }
          }
        )
    );
  }
}

screen.key(['escape', 'q', 'C-c'], tryQuit);
process.on('SIGINT', tryQuit);

setInterval(render, 10);

box.focus();
render();

let osumoSyncWatcher;
let sumoIOSyncWatcher;

run('mongod', ['mongod', '--dbpath', path.join('cache', 'db'), '--port', '25123'], () => {});
setTimeout(() => {
  run('install', ['bash', '-x', path.join('scripts', 'dev', 'install.bash')], () => {
    const runBash = (key, com) => run(
      key, ['bash', '-c', ['set -x', 'source scripts/env', `${ com } &`,
                           'echo $!', 'wait'].join('\n')], ()=>{}
    );

    runBash('server', 'girder-server').stdout.once(
      'data', (data) => serverPid = Number.parseInt(data.toString()));
    runBash('worker', 'girder-worker').stdout.once(
      'data', (data) => workerPid = Number.parseInt(data.toString()));
    runBash('watch-core', 'girder-install web --watch').stdout.once(
      'data', (data) => watchCorePid = Number.parseInt(data.toString()));
    runBash('watch-sumo',
            'girder-install web --watch-plugin osumo --plugin-prefix index'
      ).stdout.once('data',
                    (data) => watchSumoPid = Number.parseInt(data.toString()));

    osumoSyncWatcher = watch('./osumo', { recursive: true }, onOsumoChange);
    sumoIOSyncWatcher = watch('./sumo_io', { recursive: true }, onSumoIOChange);

    runTable.push({ key: 'osumo-watch', watcher: osumoSyncWatcher });
    runTable.push({ key: 'sumo-io-watch', watcher: sumoIOSyncWatcher });

  });
}, 5000); // mongod

