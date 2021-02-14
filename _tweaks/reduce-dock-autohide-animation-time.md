---
title: Reduce Dock autohide animation time
categories:
  - Dock
domains:
  - Dock/com.apple.dock
layout: tweak
---

{% assign domain = 'com.apple.dock' %}
{% assign key = 'autohide-time-modifier' %}
{% assign type = 'float' %}
{% assign value = '0' %}

## Motivation

Turning on “Automatically hide and show the Dock” (<kbd>⌥⌘D</kbd>) provides some extra general-purpose screen space. But this feature can make the Dock less usable, as the animation of the Dock sliding up from below the screen may be perceived as sluggish.

## Effects

This tweak removes the animation of the Dock sliding up from below the screen. The instant the animation would normally start, the Dock is in full view.

## Enable tweak

{% include code.md command="write" domain=domain key=key type=type value=value id=0 %}
    
## Disable tweak

{% include code.md command="delete" domain=domain key=key id=1 %}

## Related tweaks

- [Reduce Dock autohide delay](../reduce-dock-autohide-delay)
