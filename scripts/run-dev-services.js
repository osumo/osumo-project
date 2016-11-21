
/*
 * run-dev-services: convenience script for running mongod, girder, and
 *                   girder_worker together; useful for development
 *
 * Must be ran from the top of the osumo-project directory, and must have an
 * environment suitable for running all services (e.g.: virtual environments):
 *   source ./scripts/env # python virtual environment
 *   source ~/.nvm/nvm.sh # if you use nvm
 *   nvm use v6
 *   node ./scripts/run-dev-services.js
 *
 * Logging output from all three services are multiplexed into a single output
 * stream.  Each line is identified by the letter prefixing it; "M" for mongod,
 * "G" for girder, and "W" for girder_worker.  The output is also color-coded;
 * green for mongod, blue for girder, and red for girder_worker.  The stderr
 * streams for each service is also multiplexed and inverted to stand out
 * amongst the other lines of output.  All lines are word-wrapped to fit in the
 * current terminal window.  Resizing the terminal window will update the
 * word-wrapping for all new lines following the resize event.  Line
 * continuations are distinguished from new lines using hanging indents.
 */

"use strict";

const spawn = require('child_process').spawn;
const spawnSync = require('child_process').spawnSync;

let onCloseAndExit = function (callback) {
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

let chalk;

try {
  chalk = require('chalk');
} catch(e) {
  process.chdir('scripts');
  spawnSync('npm', ['install', 'chalk']);
  process.chdir('..');
  let status = spawnSync(
    process.argv[0],
    process.argv.slice(1),
    { stdio: 'inherit' }
  ).status;
  process.exit(status);
}

const styles = {
  db: [chalk.green, chalk.bgGreen],
  web: [chalk.blue, chalk.bgBlue],
  work: [chalk.red, chalk.bgRed]
};

const breakLine = (line, label, styler, indent) => {
  if (line.length) {
    let N = line.length;
    let M = N;

    let maxLength = process.stdout.columns - indent - label.length;
    if (N > maxLength) {
      N = line.lastIndexOf(' ', maxLength);
      M = N + 1;
      if (N < 0) {
        N = maxLength;
        M = N;
      }
    }

    console.log(
      `${ label }${ ' '.repeat(indent) }${ styler(line.substring(0, N)) }`);

    if (N !== line.length) {
      return breakLine(line.substring(M), label, styler, 4);
    }
  }
};

const dataHandler = (label, styler) => (data) => {
  (
    data.toString()
      .replace(/\x1B\[[0-9]+(;[0-9]+)*[mfghsuABCDH]/g, "")

      .split('')

      .map((char) => {
        let code = char.charCodeAt(0);
        return (
          (
            (code ==  9)                 || // tab
            (code == 10)                 || // newline
            (code == 13)                 || // carriage return
            (code == 32)                 || // space
            ( 33 <= code && code <= 126) || // most standard characters
            (161 <= code)                   // beyond this, we don't care
          ) ? String.fromCharCode(code) : ""
        );
      })

      .join("")

      .split('\n')

      .forEach((line) =>
        breakLine(line, label, styler, 0)
      )
  );
};

const mongodDataHandler_ = (styler) => dataHandler('M ', styler);
const girderDataHandler = (styler) => dataHandler('G ', styler);
const workerDataHandler = (styler) => dataHandler('W ', styler);

const closedHandler = (label, styler) => (exitCode) => {
  console.log(`${ label } ${ styler(`CLOSED (${ exitCode })`) }`);
};

const mongodClosedHandler_ = closedHandler('M ', styles.db[1]);
const girderClosedHandler_ = closedHandler('G ', styles.web[1]);
const workerClosedHandler_ = closedHandler('W ', styles.work[1]);

let mongodReady = false;
let currentTimeout;
const mongodDataHandler = (styler) => {
  const internalHandler = mongodDataHandler_(styler);
  return (data) => {
    if (!mongodReady) {
      if (currentTimeout) {
        clearTimeout(currentTimeout);
      }

      currentTimeout = setTimeout(() => {
        mongodReady = true;
        spawnGirderAndWorker();
      }, 500);
    }

    return internalHandler(data);
  };
};

const girderClosedHandler = onCloseAndExit((code) => {
  const result = girderClosedHandler_(code);
  webClosed();
  return result;
});

const workerClosedHandler = onCloseAndExit((code) => {
  const result = workerClosedHandler_(code);
  workerClosed();
  return result;
});

const mongodClosedHandler = onCloseAndExit((code) => {
  const result = mongodClosedHandler_(code);
  return result;
});


let girder;
let worker;

const mongod = spawn('mongod', ['--dbpath', './cache/db'], { detached: true });

mongod.stdout.on('data', mongodDataHandler(styles.db[0]));
mongod.stderr.on('data', mongodDataHandler(styles.db[1]));
mongod.on('close', mongodClosedHandler.onClose);
mongod.on('exit', mongodClosedHandler.onExit);

const spawnGirderAndWorker = () => {
  girder = spawn(
    'python',
    ['-u', '-m', 'girder'],
    { cwd: './girder',
      detached: true }
  );

  worker = spawn(
    'python',
    ['-u', '-m', 'girder_worker'],
    { cwd: './girder_worker',
      detached: true }
  );

  girder.stdout.on('data', girderDataHandler(styles.web[0]));
  girder.stderr.on('data', girderDataHandler(styles.web[1]));
  girder.on('close', girderClosedHandler.onClose);
  girder.on('exit', girderClosedHandler.onExit);

  worker.stdout.on('data', workerDataHandler(styles.work[0]));
  worker.stderr.on('data', workerDataHandler(styles.work[1]));
  worker.on('close', workerClosedHandler.onClose);
  worker.on('exit', workerClosedHandler.onExit);
};

let killDb = false;
let webKilled = false;
let workerKilled = false;

process.on('SIGINT', () => {
  killDb = true;
  if (currentTimeout) { clearTimeout(currentTimeout); }

  if (worker) { worker.kill('SIGINT'); } else { workerClosed(); }
  if (girder) { girder.kill('SIGINT'); } else { webClosed(); }
});

const webClosed = () => {
  webKilled = true;
  tryDbClose();
};

const workerClosed = () => {
  workerKilled = true;
  tryDbClose();
};

const tryDbClose = () => {
  if (killDb && webKilled && workerKilled) {
    setTimeout(() => mongod.kill('SIGINT'), 500);
  }
};

