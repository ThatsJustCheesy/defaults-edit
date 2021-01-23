---
title: “Suck” minimize effect
categories:
  - Dock
domains:
  - Dock/com.apple.dock
layout: tweak
---

{% assign domain = 'com.apple.dock' %}
{% assign key = 'mineffect' %}
{% assign type = 'string' %}
{% assign value = 'suck' %}
{% assign genie-value = 'genie' %}
{% assign scale-value = 'scale' %}

## Motivation

This tweak exposes a hidden minimize effect that, alongside “Genie” and “Scale,” has existed in the OS for a long time but has never been make public. It resembles a cross between “Genie” and “Scale.”

## Effects

This tweak sets the animation used when a window is minimized/restored to the hidden “Suck” effect.

## Enable tweak

{% include code.md command="write" domain=domain key=key type=type value=value id=0 %}
    
## Disable tweak

To disable the tweak, change the minimize effect in Dock preferences, or run one of these commands:

### Genie

{% include code.md command="write" domain=domain key=key type=type value=genie-value id=1 %}

### Scale

{% include code.md command="write" domain=domain key=key type=type value=scale-value id=2 %}
