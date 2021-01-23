{% assign id = include.id | default: 0 %}

{% if include.type %}
    {% assign typeflag = " -" | append: include.type %}
    {% assign typeurlparam = "&type=" | append: include.type %}
{% else %}
    {% assign typeflag = "" %}
    {% assign typeurlparam = "" %}
{% endif %}
{% if include.value %}
    {% assign valueurlparam = "?value=" | append: include.value %}
{% else %}
    {% assign valueurlparam = "" %}
    {% assign typeurlparam = "" %}
{% endif %}

{% assign code = "defaults " | append: include.command | append: " " | append: include.domain | append: " '" | append: include.key | append: "'" | append: typeflag | append: " " | append: include.value %}

{% assign defaults-edit-url = "defaults-edit://" | append: include.domain | append: "/" | append: include.key | append: "/" | append: include.command | append: valueurlparam | append: typeurlparam %}

<div markdown="1" id="code-{{ id }}">
```
{{ code }}
```
</div>

<button onclick="copyCode({{ id }})">Copy code</button>

<button onclick="window.open('{{ defaults-edit-url }}')">Run in defaults edit</button>
