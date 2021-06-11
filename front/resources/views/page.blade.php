@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
                <h1 class="title monda">{{ $title }} </h1>
                    {!! $content !!}
        </div>
    </div>
</div>
@endsection