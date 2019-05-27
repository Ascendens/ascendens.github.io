@extends('_layouts.master')

@section('page_title'){{ $page->title }}@endsection

@section('page_description'){{ $page->description }}@endsection

@section('body')
<article class="post">
    <header>
        <h1 class="post-title">{{ $page->title }}</h1>
        <time class="post-date" datetime="{{ date('c', $page->date) }}">{{ $page->ru_date('d M Y') }}</time>
    </header>
    {!! $page->text() !!}
</article>
@endsection

@section('bottom_js')
<script src="{{ mix('js/highlight.min.js', 'assets/build') }}"></script>
<script>hljs.initHighlightingOnLoad();</script>.
@endsection