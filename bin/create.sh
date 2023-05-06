#!/bin/bash

read -p "Enter the post title: " POST_TITLE
read -p "Enter the post category: " POST_CATEGORY

TITLE_SLUG="$(printf -- "$POST_TITLE" | sed -E 's/[^a-zA-Z0-9]+/-/g' | tr "[:upper:]" "[:lower:]")"
CATEGORY_SLUG="$(printf -- "$POST_CATEGORY" | sed -E 's/[^a-zA-Z0-9]+/-/g' | tr "[:upper:]" "[:lower:]")"

POST_DATE="$(date +%Y-%m-%d)"
POST_TIME="$(date +%H:%M)"

POST_LAYOUT=$(cat <<EOF
---
layout: post
title: $POST_TITLE
date: $POST_DATE $POST_TIME
category: $CATEGORY_SLUG
author: Akymos
tags: [$CATEGORY_SLUG]
anchor: true
---

<hr>
<h2>Table of Contents</h2>
<nav class="toc">
* toc
{:toc}
</nav>
<hr>
<div class="pb-1" />


EOF
)

POST_FILE="_posts/$CATEGORY_SLUG/$POST_DATE-$TITLE_SLUG.md"

mkdir -p "_posts/$CATEGORY_SLUG"
touch $POST_FILE
echo "$POST_LAYOUT" > $POST_FILE

exit 0