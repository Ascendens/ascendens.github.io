---
pagination:
  collection: posts
  perPage: 5
---
@extends('_layouts.master')

@section('body')
    <div class="list-documents">
        @foreach ($pagination->items as $post)
            <article class="post">
                <header>
                    <h1 class="post-title"><a href="{{ $post->getUrl() }}">{{ $post->title }}</a></h1>
                    <time class="post-date" datetime="{{ date('c', $post->date) }}">{{ $post->ru_date('d M Y') }}</time>
                </header>
                {!! $post->excerpt() !!}
                <hr />
            </article>
        @endforeach
    </div>

    @include('_partials.pagination')
@endsection