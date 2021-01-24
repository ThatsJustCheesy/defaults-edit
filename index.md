# Welcome to defaults tweaks

This is an open-source website that attempts to accessibly document the myriad of hidden settings typically accessed via the `defaults write` command on macOS.

## How to apply tweaks

Easily apply and remove tweaks at will with [defaults edit](https://github.com/ThatsJustCheesy/defaults-edit), an open-source visual defaults editor app. Each tweak on this website includes a `defaults-edit://` link. If you have the app installed, clicking one of these links will instruct it to apply or remove the tweak for you.

Alternatively, copy and paste the code provided for each tweak to a Terminal window, and restart the relevant application or system service.

# Browse tweaks

{% assign sorted_categories = site.categories | sort_natural:"title" %}
{% assign sorted_domains = site.domains | sort_natural:"title" %}
{% assign sorted_tweaks = site.tweaks | sort_natural:"title" %}

## By category

{% for category in sorted_categories %}

- [{{ category.title }}]({{ category.url | relative_url }})

{% endfor %}

## By app/domain

{% for domain in sorted_domains %}

- [{{ domain.title }}]({{ domain.url | relative_url }})

{% endfor %}

## All tweaks

{% for tweak in sorted_tweaks %}

- [{{ tweak.title }}]({{ tweak.url | relative_url }})

{% endfor %}
