---
title: Force light appearance
categories:
  - Appearance
layout: tweak
---

{% assign domain-0 = '<app>' %}
{% assign domain-1 = '-g' %}
{% assign key = 'NSRequiresAquaSystemAppearance' %}
{% assign type = 'bool' %}
{% assign value = 'true' %}

## Motivation

Some dated apps do not behave well when the system dark appearance is enabled. This tweak can force such apps to use a light appearance instead. Alternatively, this tweak can be used system-wide to mimic the "dark menu bar and dock" setting that existed in OS versions 10.10–10.13.

## Effects

This tweak forces a light appearance for a specific app, or for all apps if applied system-wide.

## Enable tweak

### For a specific app

Replace `<app>` with the bundle identifier of the app in question. Run `defaults domains` to get a complete list.

{% include code.md command="write" domain=domain-0 key=key type=type value=value id=0 %}

### System-wide

{% include code.md command="write" domain=domain-1 key=key type=type value=value id=1 %}
    
## Disable tweak

### For a specific app

Replace `<app>` with the bundle identifier of the app in question. Run `defaults domains` to get a complete list.

{% include code.md command="delete" domain=domain-0 key=key id=2 %}

### System-wide

{% include code.md command="delete" domain=domain-1 key=key id=3 %}
