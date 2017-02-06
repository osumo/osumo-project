
TUTORIAL
========

```javascript

//
// starting from minimal basics
//

// adding and removing analysis pages

let page = { name: 'testPage', key: 'test' };
let addPageAction = actions.addAnalysisPage(page);
let dispatchPromise = store.dispatch(addPageAction);

dispatchPromise.then((p) => { page = p; });
console.log(page);

store.dispatch(actions.removeAnalysisPage(page));


// multiple pages, each with name, description, and notes

let pages = [
  {
    name: 'Page 1',
    key: 'page0',
    description: 'this is the first page',
    notes: 'page 2 will follow'
  },
  {
    name: 'Page 2',
    key: 'page1',
    description: 'this is the second page',
    notes: 'no other pages after this one'
  }
];

(
  store.dispatch(actions.addAnalysisPage(pages[0]))

    .then((p) => {
      return Promise.all([
        p,
        store.dispatch(actions.addAnalysisPage(pages[1]))
      ]);
    })

    .then(([p0, p1]) => {
      pages[0] = p0;
      pages[1] = p1;
    })
);


// adding/removing elements to pages

(
  store.dispatch(actions.addAnalysisElement({
    name: 'String Input',
    key: 'string',
    description: 'enter some text',
    notes: 'it can be anything!',
    type: 'field'
  }, pages[0]))

  .then(() => store.dispatch(actions.addAnalysisElement({
    name: 'click me!',
    description: 'a plain old button',
    notes: 'seriously, it\'s just a button',
    type: 'button'
  }, pages[0])))
);


/// ENTERED 'Hello, World!'


// button doesn't do anything!  let's add a button to the second page,
// but this time, it will actually do something!

let STATE, PAGE, ACTION;
function onPage1MainAction(state, page, action) {
  STATE = state;
  PAGE = page;
  ACTION = action;

  console.log(state);
  console.log(page);
  console.log(action);
}

let registerAction = actions.registerAnalysisAction(
    'page1', 'mainAction', onPage1MainAction);
store.dispatch(registerAction);


(
  store.dispatch(actions.addAnalysisElement({
    name: 'String Input',
    key: 'string',
    description: 'enter some text',
    notes: 'it can be anything!',
    type: 'field'
  }, pages[1]))

  .then(() => store.dispatch(actions.addAnalysisElement({
    name: 'click me!',
    description: 'a plain old button',
    notes: 'seriously, it\'s just a button',
    type: 'button',
    action: 'mainAction'
  }, pages[1])))
);

/// ENTERED 'Hello, second world!'

state on click:
{
  page0: {
    string: {
      value: 'Hello, World!'
    }
  },
  page1: {
    string: {
      value: 'Hello, second world!'
    }
  }
}

```

ASIDE: if you happen to have a reference to the analysis state and analysis
       page, you can programmatically trigger the page's actions:

```javascript
const triggerAction = actions.triggerAnalysisAction(STATE, PAGE, ACTION);
store.dispatch(triggerAction);
```

### quickly creating pages

```javascript
// analysis utilites module provides helper functions to make working with
// analysis pages and elements easier

// live code examples use analysisUtils, when writing modules for real, import
// the utilities like so:
import analysisUtils from '../utils/analysis';


// managing promises for each individual page and element can be a pain, use
// processAnalysisPage to automatically create the promise chain for you!

let pageSpec = {
  name: 'Test Page',
  key: 'test',
  description: 'a test page',
  mainAction: 'main',
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

      // not necessary, since buttons will default
      // to dispatching a page's mainAction
      action: 'main'
    }
  ]
};

(
  analysisUtils.processAnalysisPage(store.dispatch, { page: pageSpec })
    .then(() => store.dispatch(actions.registerAnalysisAction(
      'test',
      'main',
      (state, page, action) => {
        let text = (((state || {})[page.key] || {}).text || {}).value || '';
        console.log(
          `You've entered the following text: ${text}`);
      }
    )))
);


// if you've recently added an analysis page, you can dispatch the 'addElement'
// action creator without providing a parent page and OSUMO will use the most
// recently created page as the default

(
  store.dispatch(actions.addAnalysisElement({
    name: 'better button',
    description: 'fetches user input using a utility function',
    type: 'button',
    action: 'betterMain'
  }))

  .then(() => store.dispatch(actions.registerAnalysisAction(
    'test',
    'betterMain',
    (state, page, action) => {
      // manually traversing the analysis state is a tedious and error-prone
      // process.  And besides, 90% of the time all you want are the "value"
      // parts of the current page's elements (you usually don't care what other
      // pages are up to, or what their internal state contains).  Quickly
      // traverse the state, pulling out only the data that this particular page
      // is working with using aggregateForm().

      let userInput = analysisUtils.aggregateForm(state, page);
      console.log(
        `You've entered the following text: ${userInput.text}`);
    }
  )))
);
```

### Writing a simple computational workflow

In this example, we will be building a simple workflow that computes the sum of
two number provided by the user.  After the sum is computed, another instance of
this computation is presented to the user with the first operand replaced by the
sum computed in the previous "step".  In this way, the user can string together
a workflow of limitless length.  This example is contrived but meant to
demonstrate the dynamic and flexible nature of the OSUMO platform.

```javascript
const sumModule = (data = {}) => {
  let hasSum = ('sum' in data);
  let index = data.index || 0;
  let pageKey = `sum-${index}`;

  const pageSpec = {
    key: pageKey,
    mainAction: 'main',
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
    const truncatePromise = store.dispatch(
      actions.truncateAnalysisPages(index + 1));
    const form = analysisUtils.aggregateForm(state, page);
    let { a, b } = form;
    const sum = Number.parseFloat(a) + Number.parseFloat(b);
    return truncatePromise.then(
      () => ({ sum, index: index + 1 })
    ).then(sumModule);
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

  return store.dispatch(actions.registerAnalysisAction(
    pageKey,
    'main',
    onMainAction
  )).then(
    () => analysisUtils.processAnalysisPage(store.dispatch, {
      page: pageSpec,
      postprocess
    })
  );
};

```

