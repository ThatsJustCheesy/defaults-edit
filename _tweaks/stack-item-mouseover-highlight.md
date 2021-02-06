---
title: Stack item mouseover highlight
categories:
  - Dock
domains:
  - Dock/com.apple.dock
layout: tweak
---

{% assign domain = 'com.apple.dock' %}
{% assign key = 'mouse-over-hilite-stack' %}
{% assign type = 'bool' %}
{% assign value = 'true' %}

## Motivation

The Grid view for folders in the Dock ("Stacks") is the most generally useful view, allowing for unlimited scrolling, Quick Look, and dragging items out. But the grid item boundaries are invisible, so it's possible to accidentally interact with the wrong item.

## Effects

This tweak highlights the background of the Stacks Grid view item the cursor is currently on top of. Despite being hidden, this feature works well and is nicely animated.

## Enable tweak

{% include code.md command="write" domain=domain key=key type=type value=value id=0 %}
    
## Disable tweak

{% include code.md command="delete" domain=domain key=key id=1 %}
