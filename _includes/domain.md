{% for tweak in site.tweaks %}

{% if tweak.domains contains page.title %}

- [{{ tweak.title }}]({{ tweak.url }})

{% endif %}

{% endfor %}