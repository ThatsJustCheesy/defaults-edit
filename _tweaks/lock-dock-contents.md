---
title: Lock Dock contents
categories:
  - Dock
domains:
  - Dock/com.apple.dock
layout: tweak
---

{% assign domain = 'com.apple.dock' %}
{% assign key = 'contents-immutable' %}
{% assign type = 'bool' %}
{% assign value = 'true' %}

## Motivation

This tweak is useful if, for any reason, you want to prevent the contents of the Dock from being modified. Perhaps you're child-proofing or setting up a kiosk machine, or perhaps you frequently drag items into pinned folders on the Dock and want to avoid accidentally adding them to the Dock instead.

## Effects

This tweak prevents any modifications to the contents of the Dock, including adding, removing and rearranging.

## Enable tweak

{% include code.md command="write" domain=domain key=key type=type value=value id=0 %}
    
## Disable tweak

{% include code.md command="delete" domain=domain key=key id=1 %}
