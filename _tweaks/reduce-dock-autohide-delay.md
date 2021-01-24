---
title: Reduce Dock autohide delay
categories:
  - Dock
domains:
  - Dock/com.apple.dock
layout: tweak
---

{% assign domain = 'com.apple.dock' %}
{% assign key = 'autohide-delay' %}
{% assign type = 'float' %}
{% assign value = '0' %}

## Motivation

Turning on “Automatically hide and show the Dock” (<kbd>⌥⌘D</kbd>) provides some extra general-purpose screen space. But this feature can make the Dock less usable, as there is a very noticeable delay between the cursor reaching to the bottom of the screen and the Dock appearing.

## Effects

This tweak removes the time delay between the cursor reaching the bottom of the screen and the Dock appearing. The instant the cursor reaches the threshold, the Dock appears.

## Enable tweak

{% include code.md command="write" domain=domain key=key type=type value=value id=0 %}
    
## Disable tweak

{% include code.md command="delete" domain=domain key=key id=1 %}
