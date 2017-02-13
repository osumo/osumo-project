
TUTORIAL
========

This tutorial will walk you through several small coding exercises, each with
the aim of demonstrating one or more concepts involved in how the OSUMO platform
works.  They start with basic manipulation of the analysis pages and elements
shown, and gradually add more concepts or more tools for simplifying the module
development process.  At the end, you will develop a simple analysis module and
gradually expand it into a fully-fledged production-ready analysis.

All code samples in this section include a preamble with the ES6 import
statements you'd write if you were writing the code for inclusion in the OSUMO
platform.  The import statements assume that the code is saved under
`osumo/web_client/analysis-modules/`, which is the section in the source code
that is dedicated to housing analysis modules.  In development mode, OSUMO
exports all the global variables you need to run the samples interactively in
the developer console.  Simply copy and paste the samples without the preamble
to see their effects live.

### Adding and removing analysis pages

This example shows how one would add and/or remove analysis pages.  The sample
is purposefully written in a very verbose style to illustrate that the global
action creators module, `actions`, export action creators, functions that return
opaque actions, that can then be dispatched to the global `store`.

The result of the dispatch is a promise that resolves to some result that is
specific to the action dispatched.  Here, we create an `addAnalysisPage` action
that adds the given page, and returns a promise on dispatch that resolves to a
copy of the internal page object that is created.  The promise chain is extended
with another that waits for 10 seconds, giving the user a chance to see the UI
elements created for the page, and then proceeds to pass the created page along
to the `removeAnalysisPage` action creator, who creates the action that removes
the page when dispatched.

```javascript
/* ES6 Imports */
import actions from '../actions';
import { store } from '../globals';
import { Promise } from '../utils/promise';
```

```javascript
let page = { name: 'testPage', key: 'test' };
let addPageAction = actions.addAnalysisPage(page);
let dispatchPromise = store.dispatch(addPageAction);

dispatchPromise.then(
  (p) => {
    /*
     * Notice that the page is not the same as the
     * object passed to the action creator, but a
     * fully constructed page object produced by the
     * underlying store's reducers.
     */
    console.log(p);

    return Promise.delay(10000).then(
      () => store.dispatch(actions.removeAnalysisPage(p)))
  }
);
```

### Adding multiple pages

Here, we add multiple pages in one go.  Careful attention is paid to the
construction of the resulting promise chain.  This care is to ensure that the
actions are dispatched- and their effects applied- in the correct order.  We
keep a reference to the promise chain at this point for attaching follow-up
actions in later samples.

```javascript
/* ES6 Imports */
import actions from '../actions';
import { store } from '../globals';
import { Promise } from '../utils/promise';
```

```javascript
const page0 = {
  name: 'Page 1',
  key: 'page0',
  description: 'this is the first page',
  notes: 'page 2 will follow'
};

const page1 = {
  name: 'Page 2',
  key: 'page1',
  description: 'this is the second page',
  notes: 'no other pages after this one'
};

const addPagePromise = (
  store.dispatch(actions.addAnalysisPage(page0))

    .then((p) => {
      return Promise.all([
        p,
        store.dispatch(actions.addAnalysisPage(page1))
      ]);
    })

    .then((pages) => {
      console.log('ADDED MULTIPLE PAGES');
      console.log(pages);

      /*
       * this promise chain resolves to
       * the two added pages in an array
       */
      return pages;
    })
);
```

### Adding elements to pages

Here, we add elements to the first page.  The `type` of each element determines
how the elements' UI features are presented as well as the primary unit of
functionality that is made available to the user.  The current selection is
modest, offering a text field, buttons, and file selection types, but will be
expanded as development continues.


```javascript
/* ES6 Imports */
/* CONTINUED FROM LAST SAMPLE */
```

```javascript
addPagePromise.then(
  ([page0,]) => (

    store.dispatch(actions.addAnalysisElement({
      name: 'String Input',
      key: 'string',
      description: 'enter some text',
      notes: 'it can be anything!',
      type: 'field'
    }, page0))

    .then(
      () => store.dispatch(actions.addAnalysisElement({
        name: 'click me!',
        description: 'a plain old button',
        notes: 'seriously, it\'s just a button',
        type: 'button'
      }, page0))
    )
  )
);
```

If you're following along with this tutorial, enter some text in the text
field and hit `ENTER`, or click the `click me` button.  You'll notice that
nothing actually happens.

### Adding behavior to analysis elements.

Here, we repeat the last sample, adding elements to the second page.  This time,
however, we include an "action" for the button element, and register a callback
for this page's action using the `registerAnalysisAction` global action creator.

The callback for the analysis action takes three parameters, a `state` object
representing the stored state for all analysis pages and their elements, a
`page` object corresponding to the page that triggered the action, and an
`action` string set to the name of the action that is triggered.

The `state` object is keyed with the keys of each analysis page, their values
are mapped to a second-level of state objects, this time keyed with the keys of
each page's analysis elements; their values, in turn, are then mapped to
generally opaque objects representing the internal state of each analysis
element.  OSUMO establishes a convention by which any state data tracked by an
analysis element that is meant to be shared outside of that element is stored
under the "value" key.  For example, the text in a text field with key "text"
under an analysis page with key "page", should be accessible by the expression
`state.page.text.value`.  Elements are free to track other state data as needed,
and these would be similarly accessible, although the exact details will vary
from element to element.

```javascript
/* ES6 Imports */
/* CONTINUED FROM LAST SAMPLE */
```

```javascript
const onPage1MainAction = (state, page, action) => {
  console.log('STATE');
  console.log(state);

  console.log('PAGE');
  console.log(page);

  console.log('ACTION');
  console.log(action);
};

addPagePromise.then(
  ([, page1]) => (

    store.dispatch(actions.registerAnalysisAction(
      page1.key, 'mainAction', onPage1MainAction))

    .then(
      () => store.dispatch(actions.addAnalysisElement({
        name: 'String Input',
        key: 'string',
        description: 'enter some text',
        notes: 'it can be anything!',
        type: 'field'
      }, page1))
    )

    .then(
      () => store.dispatch(actions.addAnalysisElement({
        name: 'click me!',
        description: 'a plain old button',
        notes: 'seriously, it\'s just a button',
        type: 'button',

        /*
         * Here, we specify that this button triggers
         * the 'mainAction' action upon being clicked.
         */
        action: 'mainAction'
      }, page1))
    )
  )
);
```

Now, when you enter text in the second text field and click the second button,
you should see the state data, triggering page object and triggered action name
printed on the console.  Upon inspection of the state data, you'll find that the
data for all pages is available, including the first page; even though it was
the second page's action that was triggered.  This observation demonstrates two
key points about the state data object: the states of all pages are available to
be read in the analysis action callbacks for all other pages, and that state
data for all elements are tracked, even those that don't have any actions
registered for them.

**NOTE**: For specialized use-cases, you can acquire or fabricate your own
      values for `state`, `page`, and `action` and then programmatically trigger
      a page's action using the `triggerAnalysisAction` global action creator,
      passing along your own values.  Just make sure that the data you pass
      matches the expectations of your callback function, and that your
      `[myPage.key, myAction]` pair actually corresponds to a real analysis
      action entry.

```javascript
store.dispatch(actions.triggerAnalysisAction(myState, myPage, myAction));
```

### Utility/Convenience functions

Now that you have a grasp of the basics of page and element manipulation and
action handling, these next samples introduce convenience functions that allow
you to build UIs with less code.  These higher-level tools allow you to reason
about your UI in terms one step above individual pages and elements.

#### quickly creating pages

Managing/Orchestrating the promises for each individual page and element can be
a tedious and error-prone task if your not very comfortable or familiar with
more advanced Promise usage patterns.  Use `processAnalysisPage` to
automatically create the promise chain for you!

The `processAnalysisPage` function takes an extended page spec as its input,
which is the same as a normal page spec but also has a `ui` field, which is a
list of element specs, for each of which analysis elements are to be created.
These elements are added to the created page.  A promise chain is returned that
resolves all these operations in the correct order.

```javascript
/* ES6 Imports */
import actions from '../actions';
import { store } from '../globals';
import { Promise } from '../utils/promise';

/* new analysisUtils module */
import analysisUtils from '../utils/analysis';
```

```javascript
const pageSpec = {
  name: 'Test Page',
  key: 'test',
  description: 'a test page',
  mainAction: 'main',

  /* list of analysis elements */
  ui: [
    {
      name: 'Text Field',
      key: 'text',
      description: 'Enter some text',
      type: 'field'
    },

    {
      name: 'Click me!',
      type: 'button',

      /*
       * Not necessary, since buttons will default
       * to dispatching a page's mainAction.
       */
      action: 'main'
    }
  ]
};

const onMainAction = (state, { key }) => {
  /*
   * Notice how accessing the state object properly requires guarding every
   * level of access.  This is because the object is populated only with new
   * state data when the state is first update.  So, for example, if a
   * newly-minted text field never has any text entered, it will not appear in
   * the state object.  In the next step, another utility function will be
   * introduced to partially address this issue.
   */
  let text = (((state || {})[key] || {}).text || {}).value || '';
  console.log(`You've entered the following text: ${text}`);
};

const registerAndCreatePromise = (
  store.dispatch(actions.registerAnalysisAction('test', 'main', onMainAction))

    .then(
      () => analysisUtils.processAnalysisPage(
          store.dispatch, { page: pageSpec }
      )
    )
);
```

#### quickly aggregating state data in action callbacks

The page created can be further manipulated just like any other page.  In this
sample, we add another button to the page with a second action, and add a
callback for this second action that does the same thing as the main action.
The difference is the second callback uses another utility function to easily
aggregate state data, `aggregateForm`.

The `aggregateForm` function takes the state object and the desired page as
input arguments, and returns the state data only for the page provided in the
form of a simple object mapping the keys of each element to the `value`
component of that element's tracked state.  Using this utility function is
usually preferred over manually traversing the analysis state, since the latter
can be tedious and error-prone.  Also for most use cases, only the "value" parts
of the current page's elements' states are what is needed.  The action callback
usually doesn't need access to the data of other pages, or other internal
element state.

```javascript
/* ES6 Imports */
/* CONTINUED FROM LAST SAMPLE */
```

```javascript
const onBetterMainAction = (state, page) => {
  let userInput = analysisUtils.aggregateForm(state, page);
  console.log(`You've entered the following text: ${userInput.text}`);
};

registerAndCreatePromise.then(() => (
  store.dispatch(actions.registerAnalysisAction(
    'test', 'betterMain', onBetterMainAction))

  .then(
    /*
     * If you've recently added an analysis page,
     * you can dispatch the 'addAnalysisElement'
     * action creator without providing a parent
     * page and OSUMO will use the most recently
     * created page as the default parent.
     */
    () => store.dispatch(actions.addAnalysisElement({
      name: 'better button',
      description: 'fetches user input using a utility function',
      type: 'button',
      action: 'betterMain'
    }))
  )
));
```

### Writing a simple computational workflow

In this example, we will be building a simple workflow that computes the sum of
two numbers provided by the user.  After the sum is computed, another instance
of this computation is presented to the user with the first operand replaced by
the sum computed in the previous "step".  In this way, the user can string
together a workflow of limitless length.  This example is contrived but meant to
demonstrate the dynamic and flexible nature of the OSUMO platform.

Note that there are a few new functions used that are not otherwise explicitly
mentioned.  The `truncateAnalysisPages` global action creator removes all
analysis pages after the first `N`.  The `updateAnalysisElementState` global
action creator is used to programmatically update the state of elements.

In addition, the `postprocess` argument for the `processAnalysisPage` utility
function is used, which allows the caller to customize each part of the page
after it is created.  The `postprocess` argument is a callback that is called
for the analysis page as well as each analysis element created.  It takes a
string describing the type of object passed, and the object, itself.  If
`type === 'page'`, then the passed `object` is the analysis page.  If
`type === 'element'`, then the `object` is one of the analysis elements.


```javascript
/* ES6 Imports */
import actions from '../actions';
import { store, rest } from '../globals';
import { Promise } from '../utils/promise';
import analysisUtils from '../utils/analysis';
```

```javascript
const sumModule1 = (data = {}) => {
  let hasSum = ('sum' in data);
  let index = data.index || 0;
  let pageKey = `sum-${index}`;

  const pageSpec = {
    key: pageKey,
    mainAction: 'main',
    name: 'Sum Module Version 1',
    ui: [
      {
        name: 'a',
        key: 'a',
        description: 'Enter a number',
        type: 'field'
      },

      {
        name: 'b',
        key: 'b',
        description: 'Enter a number',
        type: 'field'
      },

      {
        name: 'add',
        type: 'button'
      }
    ]
  };

  const onMainAction = (state, page, action) => {
    const { a, b } = analysisUtils.aggregateForm(state, page);
    const sum = Number.parseFloat(a) + Number.parseFloat(b);

    console.log('INDEX');
    console.log(index);
    return (
      store.dispatch(actions.truncateAnalysisPages(index + 1))
      .then(() => ({ sum, index: index + 1 }))

      /* pass data along to the next instance */
      .then(sumModule1)
    );
  };

  const postprocess = (
    hasSum
     ? (type, elem) => {
         if (type === 'element' && elem.key === 'a') {
           store.dispatch(actions.updateAnalysisElementState(elem, {
             value: data.sum.toString()
           }));
         }
       }
     : null
  );

  let promiseHead = Promise.resolve();
  if (!hasSum) {
    promiseHead = promiseHead.then(
      () => store.dispatch(actions.truncateAnalysisPages(0))
    );
  }

  return (
    promiseHead

    .then(
      () => store.dispatch(actions.registerAnalysisAction(
        pageKey, 'main', onMainAction))
    )

    .then(
      () => analysisUtils.processAnalysisPage(store.dispatch, {
        page: pageSpec,
        postprocess
      })
    )
  );
};

```

Finally, we call the module to kick off the first step.

```javascript
sumModule1();
```

### Moving the page spec to the server.

Here, we rewrite a new version of sumModule.  This time we will have the page
spec stored on the server, and we will fetch it when the time comes to create
the page.  The analysis utils provides another convenience function,
`fetchAndProcessAnalysisPage()`, that will automatically construct a complete
promise chain that fetches the page spec from the server, runs any requested
preprocessing step, creates the page and elements from the spec, and runs any
requested postprocessing step on the created page and elements.

The `preprocess` callback is a simpler version of the `postprocess` callback
from the `processAnalysisPage` utility function.  It directly takes the entire
page spec, including any `ui` elements as its input and can make any
modifications desired before the spec and any provided `postprocess` callback is
passed along to `processAnalysisPage`.

```javascript
const sumModule2 = (data = {}) => {
  let hasSum = ('sum' in data);
  let index = data.index || 0;
  let pageKey = `sum-${index}`;

  const onMainAction = (state, page, action) => {
    const { a, b } = analysisUtils.aggregateForm(state, page);
    const sum = Number.parseFloat(a) + Number.parseFloat(b);

    return (
      store.dispatch(actions.truncateAnalysisPages(index + 1))
      .then(() => ({ sum, index: index + 1 }))
      .then(sumModule2)
    );
  };

  /* need a different key for each instance */
  const preprocess = (page) => { page.key = pageKey; };

  const postprocess = (
    hasSum
     ? (type, elem) => {
         if (type === 'element' && elem.key === 'a') {
           store.dispatch(actions.updateAnalysisElementState(elem, {
             value: data.sum.toString()
           }));
         }
       }
     : null
  );

  let promiseHead = Promise.resolve();
  if (!hasSum) {
    promiseHead = promiseHead.then(
      () => store.dispatch(actions.truncateAnalysisPages(0))
    );
  }

  return (
    promiseHead

    .then(
      () => store.dispatch(actions.registerAnalysisAction(
        pageKey, 'main', onMainAction))
    )

    .then(
      () => analysisUtils.fetchAndProcessAnalysisPage(store.dispatch, {
        key: 'sum', preprocess, postprocess
      })
    )
  );
};

```

Also, we need to add the spec to the server, add a new file called 'sum.yml'
under `./server/ui_specs`.

```yaml
---
key: sum
name: Sum Module Version 2
mainAction: main

ui:
  - name: a
    key: a
    description: Enter a number
    type: field

  - name: b
    key: b
    description: Enter a number
    type: field

  - name: add
    type: button
```

... and make sure the server is restarted before attempting the above exercise.

### Performing Computations using girder-worker.

In this final version of the sumModule, we will move the actual addition off to
its own girder-worker job.  To facilitate data transfer to and from the job, we
will need to save intermediate results to the girder file system.  The module is
written so that if it is the first instance in the workflow, it will provide a
folder-selection dialog for selecting the location for the intermediate result
files.  When ran as a follow-up instance, it will use an analysis trigger
callback that is within a closure that keeps track of the output location, as
well as the instance's current place within the workflow order.  We use a
closure to keep track of this extra information to demonstrate one way to do so.
There are other ways to pass and/or track extra information from analysis page
to analysis page, such as using hidden elements or reading directly from the
state data of prior pages.

The analysis utils module provides a high-level function for running OSUMO jobs
and accessing their results, `runTask`.  This function returns an extensive
promise chain that will create the girder-worker job, schedule it for execution,
periodically poll for its status, wait for the job to complete successfully, and
then fetch and return metadata describing the output files created by the job.
The chain will also reject with an appropriate error if anything goes wrong
along the way.

```javascript
const sumModule3 = (data = {}) => {
  let hasSum = ('sum' in data);
  let hasOutputId = ('outputId' in data);
  let index = data.index || 0;
  let pageKey = `sum-${index}`;
  let outputId = data.outputId;

  /* NOTE: onMainAction has access to index and outputId */
  const onMainAction = (state, page, action) => {
    const truncatePromise = store.dispatch(
      actions.truncateAnalysisPages(index + 1));
    const form = analysisUtils.aggregateForm(state, page);

    if (!hasOutputId) {
      outputId = form.outputId;
    }

    const task = 'sum';
    const inputs = {
      a: `FLOAT:${form.a}`,
      b: `FLOAT:${form.b}`
    };
    /*
     * we specify the output format as "json" so that
     * girder-worker knows how to write the data out to disk
     */
    const outputs = {
      sum: `FILE:${outputId}:sum-${index}("format":"json")`
    };
    const title = 'sum';
    const maxPolls = 40;

    const runPromise = (
      analysisUtils.runTask(task, { inputs, outputs }, { title, maxPolls })

      .then((files) => {
        let sumId;

        files.forEach(({ fileId: fid, name }) => {
          if (name === `sum-${index}`) { sumId = fid; }
        });

        return (
          rest({ path: `file/${sumId}/download` })
            .then(({ response }) => ({
              sum: Number.parseFloat(response),
              index: index + 1,
              outputId
            }))
        );
      })
    );

    return Promise.all([
      truncatePromise,
      runPromise
    ]).then(
      ([, data]) => data
    ).then(sumModule3);
  };

  const preprocess = (page) => {
    page.name = 'Sum Module Version 3';
    page.key = pageKey;

    /*
     * If this is the first step, insert the
     * folder selection element before the button.
     */
    if (!hasOutputId) {
      page.ui.push(page.ui[2]);
      page.ui[2] = {
        key: 'outputId',
        type: 'folderSelection',
        name: 'Output Location',
        description: 'Location for intermediate results'
      };
    }
  };

  const postprocess = (
    hasSum
     ? (type, elem) => {
         if (type === 'element' && elem.key === 'a') {
           store.dispatch(actions.updateAnalysisElementState(elem, {
             value: data.sum.toString()
           }));
         }
       }
     : null
  );


  let promiseHead = Promise.resolve();
  if (!hasSum) {
    promiseHead = promiseHead.then(
      () => store.dispatch(actions.truncateAnalysisPages(0))
    );
  }

  return (
    promiseHead

    .then(
      () => store.dispatch(actions.registerAnalysisAction(
        pageKey, 'main', onMainAction))
    )

    .then(
      () => analysisUtils.fetchAndProcessAnalysisPage(store.dispatch, {
        key: 'sum',
        preprocess,
        postprocess
      })
    )
  );
};
```

Also, we need to add the task spec and associated script to the server, add a
new file called 'sum.yml' under `./server/task_specs`.  In this case, the script
is so simple that we add it inline.

##### sum.yml
```yaml
name: sum
mode: r

script: "sum <- a + b"

inputs:
  - name: a
    type: number
    format: number

  - name: b
    type: number
    format: number

outputs:
  - name: sum
    type: number
    format: number
    target: memory
```

... finally, make sure you restart the server before running this module.

### Conclusion

In this tutorial, you were shown how the mechanics of managing analysis pages
and elements work and how to take advantage of them to quickly create custom and
responsive UIs allowing your users to directly interface with your computational
workflows.  Some final notes to consider are the following:

 - By convention, the sources for all analysis modules are kept under the
   `osumo/web_client/analysis-modules/` directory.  When adding modules, you
   should place their source code files in there.

 - In addition, there is a particular file among the analysis modules,
   `osumo/web_client/analysis-modules/base-listing.jsx` that contains a static
   listing of all analysis modules that constitute the "first step" in an
   analysis workflow.  When adding new workflows, you will need to add an entry
   to this list.  The contents of the list correspond to the options provided in
   the drop-down menu on the top of the analysis page interface.

