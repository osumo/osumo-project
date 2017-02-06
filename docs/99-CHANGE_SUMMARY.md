
CHANGE SUMMARY
==============

  - Migrated to Girder 2.x

    - We now take advantage of new Girder 2.x features, such as client-side
      collection filtering to enable file and folder selection dialogs that only
      show appropriate items for selection.

    - Switched to using Girder's webpack infrastructure for building client
      code.

    - Split job specs into two separate spec file types.

      - Task Specs

        - Just the "task" part of a girder-worker job; used as a "cookie-cutter"
          template for OSUMO jobs.

        - Can use new route: /osumo/tasks/:key/run to quickly create a job from
          the task spec.

          - Takes parameters that use a new shorthand notation for specifying
            girder input/output bindings that, compared to the more-verbose
            binding spec in girder-worker, is more compact for common use cases.

            - Examples:

              - "INPUT(myVariable)": "FILE:2ae0417dcab9" specifies that the data
                for the job's input variable "myVariable" should be read from
                the girder file with id "2ae0417dcab9".

              - "OUTPUT(myVariable)": "FILE:2ae0417dcab9" specifies that the
                data in the job's output variable "myVariable" should be written
                to a new girder file under the girder folder with id
                "2ae0417dcab9".

            - Ultimately, this shorthand is just a convenience that isn't
              stricltly necessary.  Removing it and just going back to regular
              girder-worker syntax is totally on the table.

      - UI Specs

        - New spec for quickly building sophisticated frontend UI forms.

        - Uses a declarative approach where users create their forms using a
          preset collection of building blocks.  These building blocks are
          pre-written components like buttons, text fields, and images.

        - Behavior/Coordination/Orchestration is handled by the client-side code
          users write for each of their workflows.  These workflow modules,
          together with the task specs and UI specs, are the three pillars upon
          which new analayses applications can be rapibly produced.

  - Client Application Changes

    - Reducers have been completely overhauled.  The custom compose solution has
      been replaced with redux's combineReducers + fewer reducers that operate
      on a more coarse level.

      - Global actions have been replaced with global action creators according
        to established React + Redux best practices.

        - All global action creators now use redux-thunk to expose a uniform API
          for action dispatches.  Now, every global action creator returns a
          chainable promise on dispatch, even if it is not asynchronous, or
          doesn't even dispatch an action.

    - Added infrastructure for analysis modules

      - See web_client/utils/analysis.jsx

