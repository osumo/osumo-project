
import { createStore } from "redux";

/* VERSION 1 -- (16 NON-WHITESPACE LINES) ------- */

const addToList = (state=[], action) => {
  return [...state, action.value];
};

const removeFromList = (state=[], action) => {
  return state.filter(x => (x === action.value));
};

const rootReducer = (state=[], action) => {
  switch(action.type) {
    case "ADD_TO_LIST":
      return addToList(state, action);
    case "REMOVE_FROM_LIST":
      return removeFromList(state, action);
    default:
      return state;
  }
};



/* VERSION 2 -- (33 NON-WHITESPACE LINES) ------- */

const addToList = (state=[], action) => {
  return [...state, action.value];
};

const removeFromList = (state=[], action) => {
  return state.filter(x => (x === action.value));
};

const setScalar = (state=null, action) => {
  return action.value;
};

const DSTATE = {
  list: [],
  title: "The Default Title"
};

const rootReducer = (state=DSTATE, action) => {
  let newList, newTitle;
  switch(action.type) {
    case "ADD_TO_LIST":
      newList = addToList(state.list, action);
    break;
    case "REMOVE_FROM_LIST":
      newList = removeFromList(state.list, action);
    break;
    case "SET_TITLE":
      newTitle = setScalar(state.title, action);
    break;
  }

  let stateChanged = (newList  !== state.list ||
                      newTitle !== state.title);

  if(stateChanged) {
    state = { list: newList, title: newTitle };
  }

  return state;
};



/* VERSION 3 -- (63 NON-WHITESPACE LINES) ------- */

const addToList = (state=[], action) => {
  return [...state, action.value];
};

const removeFromList = (state=[], action) => {
  return state.filter(x => (x === action.value));
};

const setScalar = (state=null, action) => {
  return action.value;
};

const incrementScalar = (state=0, action) => {
  let amount = action.amount || 1;
  return state + amount;
};

const DLIST = { values: [], length: 0 };

const DSTATE = {
  list: DLIST,
  title: "The Default Title"
};

const rootReducer = (state=DSTATE, action) => {
  let newList, newTitle, newLength;
  switch(action.type) {
    case "ADD_TO_LIST":
      newList = addToList(
        state.list.values, action);

      newLength = incrementScalar(
        state.list.length, { amount: 1 });
    break;
    case "REMOVE_FROM_LIST":
      newList = removeFromList(
        state.list.values, action);

      newLength = setScalar(
        state.list.length,
        { value: newList.length });
    break;
    case "SET_LENGTH":
      newLength = action.value;
      newList = state.list.values;

      if(newLength < state.list.length) {
        newList = newList.slice(0, newLength);
      } else if(newLength > state.list.length) {
        newList = newList.slice();
        let i;
        for(i=newList.length; i<newLength; ++i) {
          newList.push(null);
        }
      }
    break;
    case "SET_TITLE":
      newTitle = setScalar(state.title, action);
    break;
  }

  let stateChanged = (
    newList   !== state.list.values ||
    newLength !== state.list.length ||
    newTitle  !== state.title);

  if(stateChanged) {
    state = {
      list: { values: newList, length: newLength },
      title: newTitle
    };
  }

  return state;
};





















/* VERSION 1' -- (14 NON-WHITESPACE LINES: -2) -- */

import { compose } from "./utils/reducer";

const addToList = (state=[], action) => {
  return [...state, action.value];
};

const removeFromList = (state=[], action) => {
  return state.filter(x => (x === action.value));
};

const list = (
  compose({
    add: addToList,
    remove: removeFromList
  })

  .defaultState([])
);



/* VERSION 2' -- (30 NON-WHITESPACE LINES: -3) -- */

import { compose } from "./utils/reducer";

const addToList = (state=[], action) => {
  return [...state, action.value];
};

const removeFromList = (state=[], action) => {
  return state.filter(x => (x === action.value));
};

const setScalar = (state=null, action) => {
  return action.value;
};


const list = (
  compose({
    add: addToList,
    remove: removeFromList
  })

  .defaultState([])
);

const scalar = (
  compose({
    set: setScalar
  })

  .defaultState(null)
);

const root = (
  compose({})

  .children({
    list: list,
    title: scalar.defaultState("The Default Title")
  })
);



/* VERSION 3' -- (88 NON-WHITESPACE LINES: +25) - */

import { compose } from "./utils/reducer";

const addToList = (state=[], action) => {
  return [...state, action.value];
};

const removeFromList = (state=[], action) => {
  return state.filter(x => (x === action.value));
};

const setScalar = (state=null, action) => {
  return action.value;
};

const incrementScalar = (state=0, action) => {
  let amount = action.amount || 1;
  return state + amount;
};


const list = (
  compose({
    add: addToList,
    remove: removeFromList
  })

  .defaultState([])
);

const scalar = (
  compose({
    set: setScalar,
    increment: incrementScalar
  })
);

const stateUpdate = (state, mapping) => {
  let newState = state;
  (
    Object.entries(mapping)
    .forEach(([key, value]) => {
      if(newState === state &&
         newState[key] !== value)
      {
        newState = { ...state };
      }

      newState[key] = value;
    })
  );

  return newState;
};

const lengthTrackedList = (
  compose({
    "values/add": (_, _, delegate) => {
      let state = delegate(
        this("actions").values.add
      );

      state.values = this("reducers").values.add(
        state.values,
        {
          ...action,
          type: this("actions").values.add
        }
      );

      return stateUpdate(
        state,
        { length: state.values.length }
      );
    },

    "values/remove": (_, _, delegate) => {
      let state = delegate();
      return stateUpdate(
        state,
        { length: newList.length }
      );
    },

    "length/set": (_, _, delegate) => {
      let state = delegate();
      let newList = state.list.values;

      if(newLength < newList.length) {
        newList = newList.slice(0, newLength);
      } else if(newLength > newList.length) {
        newList = newList.slice();
        for(let i=newList.length; i<newLength; ++i) {
          newList.push(null);
        }
      }

      return stateUpdate(
        state,
        { values: newList }
      );
    },

    "length/increment": (state={}, action) => state
  })

  .children({
    values: list,
    length: scalar.defaultState(0)
  })
);



const root = (
  compose()

  .children({
    list: lengthTrackedList,
    title: scalar.defaultState("The Default Title")
  })
);

