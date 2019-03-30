@extends('_layouts.master')

@section('page_title')
{{ $page->title }}
@endsection

@section('body')
<article class="post">
    <header>
        <h1 class="post-title">{{ $page->title }}</h1>
        <time class="post-date" datetime="{{ date('c', $page->date) }}">{{ date('d M Y', $page->date) }}</time>
    </header>
    {!! $page->text() !!}
</article>
@endsection