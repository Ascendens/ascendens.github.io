---
pagination:
    collection: posts
    perPage: 5
---
@extends('_layouts.master')

@section('body')
<div class="list-documents">
    @foreach ($posts as $post)
        <article class="post">
            <header>
                <h1 class="post-title"><a href="{{ $post->getUrl() }}">{{ $post->title }}</a></h1>
                <time class="post-date" datetime="{{ date('c', $post->date) }}">{{ date('d M Y', $post->date) }}</time>
            </header>
            {!! $post->excerpt() !!}
            <hr />
        </article>
    @endforeach
</div>
@endsection