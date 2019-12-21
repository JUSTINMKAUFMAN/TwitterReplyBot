# TwitterReplyBot
Automate Tweet-replies to mentions for a specified user

<p>
    <a href="https://github.com/JUSTINMKAUFMAN" rel="nofollow"><img src="https://camo.githubusercontent.com/1a8ae43a475543efd8c1b1a0d4cad4ec09a3a95d/68747470733a2f2f696d672e736869656c64732e696f2f636f636f61706f64732f762f546f704472617765722e7376673f7374796c653d666c6174" alt="Version" data-canonical-src="https://img.shields.io/cocoapods/v/TopDrawer.svg?style=flat" style="max-width:100%;">
    </a>
    <a href="https://github.com/JUSTINMKAUFMAN" rel="nofollow"><img src="https://camo.githubusercontent.com/9e25ea9748467982675f953c0672b4149ae30faa/68747470733a2f2f696d672e736869656c64732e696f2f636f636f61706f64732f6c2f546f704472617765722e7376673f7374796c653d666c6174" alt="License" data-canonical-src="https://img.shields.io/cocoapods/l/TopDrawer.svg?style=flat" style="max-width:100%;">
    </a>
    <a href="https://github.com/JUSTINMKAUFMAN" rel="nofollow"><img src="https://camo.githubusercontent.com/e2a21ce7469082b68c3a5fa680d28c041516eea0/68747470733a2f2f696d672e736869656c64732e696f2f636f636f61706f64732f702f546f704472617765722e7376673f7374796c653d666c6174" alt="Platform" data-canonical-src="https://img.shields.io/badge/platform-macOS-blue.svg?style=flat" style="max-width:100%;">
    </a>
<p>

<p align="center">
    <img src="/TwitterReplyBot.png" />
</p>

#### NOTE: You will need to create a Twitter Developer account and create an API Key/Secret in order to use this software.

## Overview

This is a modular Twitter reply bot written in Swift.

At a high-level, that means you create `Module`s consisting of a single function that return an output string for some input Tweet:

`func output(for reply: Reply, _ completion: @escaping ((String) -> Void))`

The `Bot` then calls its module's `output` method anytime it detects a new Tweet and automatically posts a reply (from the bot) with the string it received.

## Background

This project was motivated by a contest I've been running on Twitter called `Codebreaker`:
https://github.com/JUSTINMKAUFMAN/TwitterCodebreaker

The idea is to have a bot monitor a Tweet (or an account more generally) and process all replies into a coded response from the bot. Users then compete to be first to figure out the bot's encryption algorithm.

The modules I have included in this app as examples are from the first two rounds of that contest.

## Installation

Option 1: Clone this repository and build the app with Xcode 11.3.
Option 2: Download the latest built binary from releases, unzip, and run.

## Getting Started

1. Run the app and enter your Twitter API Key/Secret in the input fields at the bottom of the window
2. Click `Update`
3. Send a tweet to the bot and watch it reply!
4. Add your own `Module`

## Credit

In order to authorize and communicate with the Twitter API, this app copies and modifies source from the excellent [Swifter]( https://github.com/mattdonnelly/Swifter) library by Matt Donnelly. In the future - and assuming there is interest in this project - I will probably try to fork the Swifter library properly; this was just easier when I wasn't sure where the project was going.

#### © 2020 Justin Kaufman
