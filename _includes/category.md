{% for tweak in site.tweaks %}

{% if tweak.categories contains page.title %}

- [{{ tweak.title }}]({{ tweak.url }})

{% endif %}

{% endfor %}