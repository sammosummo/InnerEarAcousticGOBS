# Inner-Ear Assessments for Acoustic GOBS

## Versions

2023-12-03 Initial version.

## Introduction

This repository contains code for running the inner-ear assessments for the
Acoustic GOBS project. This document describes how to run these assessments
and inspect the resulting data.

If any issues arise that are not covered below, please let me know ASAP and
I'll modify this document and the code if necessary.

## Equipment

The inner-ear assessments require the following hardware:

1. Interacoustics Titan
2. Wideband tympanometry (WBT) cavity kit
3. Sanibel ear tips
4. Windows PC

### Interacoustics Titan

The Titan is the inner-ear analyser we use to perform all assessments. It
is primarily a clinical diagnostic tool, but can be used for research
purposes with the appropriate licensing and firmware modification. Once
configured for research, the Titan's API is exposed to Matlab, and Matlab
code provided by Interacoustics can be used to run arbitrary assessments.

The San Antonio Titan has already been configured for research. However, it
is possible to undo this configuration by mistake, by opening the Titan
Suite (a software application for clinical tympanometry we don't use) and
clicking "yes" on the prompt to update the firmware. This operation
reinstates the clinical firmware on the device and must be undone by
reinstalling the research firmware. Let me know ASAP if this occurs.

### WBT cavity kit

The Titan must be calibrated using the WBT cavities to ensure valid data.
Importantly, ***these are not the standard cavities that come with the
device!*** They are separate equipment.

At the time of writing, we do not have these cavities. I have come up with
a temporary workaround, described later.

### Sanibel ear tips

A fresh ear tip is needed each time the Titan probe is placed in a new ear
(i.e., two per individual). Always try a 14-mm (red) "mushroom"-shaped tip
first, and switch to a different size (and color) if you experience fitting
issues.

The example data (subject ID "sam") were collected using the 13-mm (green)
tip. For reference, I'm 5'7'' male.

Avoid using the other tip styles (e.g., umbrella, flanged, insert) and tips
from another manufacturer (e.g., Grayson), as these are meant for different
situations and will likely work less well for our purposes.

### Windows PC

The Titan is connected to the Windows PC running Matlab via USB.

## Procedure

### Overview

Inner-ear assessments are always performed after otoscopy and audiometry,
and on the **right ear first**. The general procedure is as follows.

1. Open Matlab
2. Calibrate
3. Prepare the participant
4. Insert the ear tip
5. Run an assessment
6. Inspect the results
7. Repeat steps 5 and 6 until done

### Opening Matlab

Once opened, set Matlab's working directory to this one. You should see
this file (`README.txt`) and the main script (`AcousticGOBS.m`), various
subfolders, and many other files.

### Calibration

The inner-ear assessments require at leat one valid calibration file. 
Calibration files are named like so:

```
{this_directory}/Calibration/AcousticGOBSCal_{date}_{timestamp}.mat
```

If more than one calibration file is present, the latest one is used. If
there are no calibration files when the main script (`AcousticGOBS.m`) is
run, the main script will prompt you to perform a calibration. Calibration
files can also be created at any time, separate from assessments, via the
calibration script (`AcousticGOBSCal.m`).

Basically, calibration is used to compensate the inner-ear assessments for
the uninteresting acoustic properties of the ear canal, "cleaning up" the
data and leaving us with the interesting properties of the inner ear.
Calibration involves playing sounds into "cavities" of known shape and
volume and recording the acoustic properties of those cavities.

Because something could change within the Titan, you should perform a fresh
calibration every 90 days or so.

Each time you run a calibration, it is important to check how it went. Each
calibration saves a figure named like so:

```
{this_directory}/Figures/AcousticGOBSCal_{date}_{timestamp}.fig
```

I have included a configuration file and figure in the repository. These
measurements were made using the Boston Titan and are therefore not valid
for the San Antonio Titan, but the figure is illustrative of a decent
calibration. Open the figure by double-clicking on it in Matlab. See how
the orange lines (measured values) line up well with the blue lines
(expected values)?

As mentioned above, WBT calibration requires special WBT cavities. The
Titan comes with some cavities, but these are **not the ones we want**. At
the time of writing, we don't have the correct cavities, so we will use the
workaround described in the next section until they arrive.

#### Temporary workaround

For now, run participants using the example calibration file.

I made some cavities with roughly the same dimensions as the those in the
official WBT cavity kit. They are currently in my Boston lab, but I will
ship them to you. When they arrive, run a calibration for yourself.

Take a look at the resulting figure and make sure it looks similar to the
Boston calibration figure. You may need to run the calibration script a few
times. Make sure the latest calibration script is the one you are happiest
with, and delete the bad ones just to be safe.

When you eventually recieve the official cavities, run a new calibration.
After this point, run calibration again with the official cavities every 90
days or so.

### Participant preparation

Inform the participant that we are about to take some acoustic measurements
from their ears. This will involve placing a microphone in the ear. This
will sometimes pump a very small amount of air into the ear canal to change
its pressure, and sometimes play sounds. Sometimes, the sounds can be loud,
but the loud sounds never last long.

All the participant needs to do is remain seated, and stay still. When you
say "stay still", the participant should try to keep their gaze directly
forward, not look around, not move their head up or down or side to side.
They shouldn't swallow, speak, or yawn. They shouldn't grind their teeth
or clench their jaw, or tense or move any other part of their body, such as
their arms and legs. They'll only need to stay still during the assessments
themselves, and none of them last more than about 4 minutes.

### Performing assessments

Besides the calibration script, the only script you should ever need to run
is the main script, `AcousticGOBS.m`. The script performs four assessments:

1. Three-dimensional tympanometry (3DT)
2. Wideband reflexes (WBR)
3. High-pass reflexes (HPR)
4. Distortion product otoacoustic emissions (DPOAE)

Assessments are always conducted in this order, and in the subject's right
ear first, followed by their left ear.

When you run the script, first it will prompt you to enter a subject ID.
Then it will search for a file containing the subject's right-ear 3DT data.
If this file is not found, it will give you the option to perform the
assessment or skip it. It repeats this process until all assessments are
done.

Data belonging to a specific combination of subject, ear, and assessment
are saved upon completion of that part of the procedure. Sometimes, an
assessment may fail or raise an error, or you may need to quit the script
before all assessments are completed. To resume an incomplete procedure,
just run the script again and enter the same subject ID. It will pick up
where it left off.

Skipping is allowed if you cannot get data for some reason. For example,
sometimes 3DT cannot form a good seal and will repeatedly crash.

### Inserting the ear tip

Make sure the probe is clean by running floss through each hole before it
goes in the participant's ear for the first time. Clip the transducer (the
white part with a circle in the middle) onto the participant's clothing
**contralaterally to the ear you are testing.** For example, if you are
testing the right ear, clip the transducer on the left and trail the cable
across the participant's front. This adds a bit of extra force to the probe
in the direction of the ear and helps form a consistent seal. Have the 
participant move their head from side to side gently to make sure that the
probe stays in place.

Once you have performed an assessment and the next assessment is in the
same ear, you should check that the probe is still inserted OK. You don't
have to take it out if it looks good.

When it's time to switch ears, take of the ear tip and clean the probe. Use
a new ear tip in the new ear.

### Data inspection

Data files are stored in the `Measurement/` subdirectory and are named like
so:

```
{this_directory}/Measurement/AcousticGOBS{assessment}_{subject_id}_{ear}.mat
```

These are not meant to be readable, but it's good to check they exist!

Each assessment also generates a figure, named like so:

```
{this_directory}/Figures/AcousticGOBS{assessment}_{subject_id}_{ear}.fig
```

Take a look at the figures associated with the subject ID "sam" to get a
sense of what each should look like. Sometimes the data may look weird or
bad. If this happens, you should kill the script (Ctrl-C), delete/rename
the offending assessment data and figure, and rerun. The next sections give
specific guidence for each assessment.

## Assessments

This section describes each of the assessments in simple terms so you know
what to expect and what may go wrong.

### 3DT

Tympanometry is a clinical tool to check for coarse abnormalities in the
ear. It is not really scientifically interesting, but can be used to
exclude ears from some analyses later on. "3D" or wideband tympanometry is
just a fancier version of basic clinical tympanometry developed by
Interacoustics.

During this assessment, the Titan will increase the pressure in the ear by
pumping air in, then decrease the pressure by pumping air out. During this
sweep from high to low pressure, it plays a "click train". A click is a
very brief sound that consists of many frequencies and has a sharp attack
and decay, and a train is just a rapid sequence of clicks. 

3DT generates a three-dimensional plot that should look a bit like a
mountain range. It should have a "ridge" going from low to high frequencies
that is pointiest at 0 pressure. See the example plots. Large flat portions
of the 3DT are more likely to be a biological abnormality than an artifact.

The biggest pain point with 3DT is that it will raise an error if it fails
to change the inner ear pressure. This happens when it fails to make a
proper seal, but it can also happen if the ear canal is a funny shape. If
you can't get 3DT to run after 3 attempts, skip it.

Rerun 3DT if:

- It crashes once or twice
- You see a weird shape, should as a valley, a big spike, or many little
  spikes

Skip if:

- It consistently crashes

### WBR

WBR always runs wideband absorbance (WBA) immediately before itself. This
is identical to 3DT but without the pressure sweep, so the WBA figure (see
examples) should look more or less exactly like the mountain ridge at zero
pressure in the 3DT figure. Don't worry about WBA.

When the ear is presented with a loud sound, there is a muscle contraction
(reflex) that absorbs some of the acoustic energy to protect the ear. This
is what WBR measures. During WBR, the participant with hear a click train
as before, but in between each click will be a burst of noise. The noise
burst steadily gets louder and louder, and we measure the reflex as a
function of this.

All of the lines is the top and middle panels of the WBR figure should more
or less line up (see examples). In the bottom panel, the we should see more
pronounced differences between the lines. It is OK if some of the lines in
this panel are basically flat, but they shouldn't all be completely flat.
If so, this suggests that the probe is not inserted properly or that the
calibration is off.

I haven't seen WBR raise any errors.

Rerun if:

- You see absolutely nothing in the bottom panel the first time. But if it
  happens again, keep it.

### HPR

HPR is identical to WBR except that the noise burst is a bit different. It
produces weaker reflexes that WBR, so the differences between the lines in
the bottom panel of the figure may be smaller. However, again, not all
lines should be completely flat.

### DPOAE

DPOAE starts by playing a brief blip of two tones with similar frequencies,
called f1 and f2. Then f1 and f2 are played again, but this time for about
20 seconds. During the longer tones, the Titan records additional sounds
that the ear creates itself, called "distortion products". You can see f1,
f2, and the distortion product in the top panel of the figure. It does this
13 times.

DPOAE is quite forgiving about participant movement and noise as it has
rudimentary built-in artifact rejection. I sneezed during one of my runs
and you can't tell where (see example figures). It takes longer the more it
has to reject, however.

In the middle panel, you will see two data points, the distortion product
(orange) and the noise floor (blue). Orange should be higher than blue for
the first 5 or 6 frequencies, but the distortion product will die away at
the later frequencies. If orange is never higher than blue, that's is a
problem.

DPOAE has a pain point. The brief blips are used to quickly calibrate the
longer tone pairs. I don't know why, but sometimes this goes awry, and it
tries to make the tone pairs too loud and you get a voltage warning. This
seems to happen when the probe is not properly inserted.

Rerun if:

- Multiple missing frequencies due to voltage warning. 


## Duration

Total pure assessment time is about 20 minutes, not including participant
preparation and calibration. A complete run on myself took under 20 mins.


 
