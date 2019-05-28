<div class="pagination" role="navigation">
    <span class="pagination-item newer">@if ($next = $pagination->next)
            <a href="{{ $page->baseUrl }}{{ $next }}" rel="next">Предыдущие</a>
        @elseПредыдущие@endif</span>
    <span class="pagination-item older">@if ($previous = $pagination->previous)
        <a href="{{ $page->baseUrl }}{{ $previous }}" rel="prev">Следующие</a>
    @elseСледующие@endif</span>
</div>