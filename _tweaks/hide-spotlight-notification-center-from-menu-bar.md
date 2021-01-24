---
title: Hide Spotlight and Notification Center menu bar icons
categories:
  - Menu bar
  - Spotlight
  - Notification Center
domains:
  - Spotlight/com.apple.Spotlight
  - SystemUIServer/com.apple.systemuiserver
layout: tweak
---

{% assign domain-0 = 'com.apple.Spotlight' %}
{% assign domain-1 = 'com.apple.systemuiserver' %}
{% assign key-0 = 'NSStatusItem Visible Item-0' %}
{% assign key-1 = 'NSStatusItem Visible Item-0' %}

## Motivation

Most system menu bar items can be removed, either in System Preferences, or by holding down the Command key and dragging them off the menu bar. But there are two exceptions to this rule: the Spotlight search button and the Notification Center button. These functions have keyboard and trackpad equivalents, and if you're used to using those instead, these two buttons become a rather useless waste of space.

## Effects

This tweak removes the Spotlight and/or Notification Center icons from the menu bar.

## Enable tweak

### Spotlight

{% include code.md command="write" domain=domain-0 key=key-0 type="bool" value="false" id=0 %}

### Notification Center

{% include code.md command="write" domain=domain-1 key=key-1 type="bool" value="false" id=1 %}
    
## Disable tweak

### Spotlight

{% include code.md command="delete" domain=domain-0 key=key-0 id=2 %}

### Notification Center

{% include code.md command="delete" domain=domain-1 key=key-1 id=3 %}
