## Nimbus Experiment Targeting Attributes
When creating experiments that target iOS users using [`experimenter`](https://experimenter.services.mozilla.com/nimbus/), experiment creators can add custom **targeting attributes** that target specific user segments.

This document lists the existing targeting attributes experiment creators can use.

### First Startup Targeting
An experiment creator can target users who are on their very first run of the app. This is useful for running experiments on features that can improve a new user's experience.

> Note: this will also target users who wipe their app's data (or re-install their app)

On experimenter, this is called `First start-up users` on the Advanced Audiences drop down.

#### Limitations
First startup experiments have one main limitation, since experiments need to be retrieved from the network,
there will be a delay from the start of the app until the experiment data is ready. On subsequent runs this is okay,
because experiment data is cached between runs. However, on first startup, the experiment data will not be ready until
the data is retrieved from the network (on a fast network about 1 second or so from the time the user launches the app)

It's important that an experiment that targets first-run users considers the delay, especially if the experiment runs early
in the user's experience with the app, as the data might not be ready by then.
