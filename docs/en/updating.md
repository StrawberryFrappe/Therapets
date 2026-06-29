---
title: Updating the App
parent: User Guide
lang: en
nav_order: 10
description: "Update channels and the in-app update process."
---

# Updating the App
{: .no_toc }

1. TOC
{:toc}

## Channels

Therapets is distributed through three channels (see [Installation](installation.html)):

- **Stable** — production releases (`vX.Y.Z`).
- **Nightly** — builds from the `dev` branch (`vX.Y.Z-nightly.N`).
- **Unstable** — experimental builds (`vX.Y.Z-unstable.N`).

## In-app update

The app checks whether a newer version is available on GitHub Releases.
When one is found, an **update icon** appears in the HUD.

1. Tap the update icon.
2. The app downloads the APK for the new version.
3. The Android installer is launched (thanks to the
   `REQUEST_INSTALL_PACKAGES` permission).
4. Confirm to install over the current version.

> Your data (pet, coins, missions) is preserved across updates: it is stored
> in local storage with automatic migration from older formats.
{: .note }

## Manual update

You can also download the latest APK directly from the
[GitHub Releases](https://github.com/StrawberryFrappe/Therapets/releases) page and
install it over the existing version.
