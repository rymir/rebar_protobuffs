-module('rebar_protobuffs_prv').

-export([init/1, do/1, format_error/1]).

-define(PROVIDER, 'compile').
-define(DEPS, [{default, compile}]).

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
            {name, ?PROVIDER},            % The 'user friendly' name of the task
            {namespace, protobuffs},
            {module, ?MODULE},            % The module implementation of the task
            {bare, true},                 % The task can be run by the user, always true
            {deps, ?DEPS},                % The list of dependencies
            {opts, []},                   % list of options understood by the plugin
            {example, "rebar3 protobuffs compile"},
            {short_desc, "Automatically compile protobuffs"},
            {desc, "Protobuff compiler"}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.


-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    Apps = case rebar_state:current_app(State) of
        undefined ->
            rebar_state:project_apps(State);
        AppInfo ->
            [AppInfo]
    end,
    lists:foreach(fun(AppInfo) ->
                Opts        = rebar_app_info:opts(AppInfo),
                ProtoDir    = case dict:find(proto_dir, Opts) of
                    error -> "proto";
                    {ok, Found} -> Found
                end,
                OutDir      = rebar_app_info:ebin_dir(AppInfo),
                InclDir     = filename:join([rebar_app_info:out_dir(AppInfo), "include"]),
                SourceDir   = filename:join([rebar_app_info:dir(AppInfo), ProtoDir]),
                FoundFiles  = rebar_utils:find_files(SourceDir, ".*\\.proto\$"),

                CompileFun  = fun(Source, Opts1) ->
                        do_compile(Source, InclDir, OutDir, Opts1)
                end,

                rebar_base_compiler:run(Opts, [], FoundFiles, CompileFun)
        end, Apps),
    {ok, State}.

do_compile(Source, InclDir, OutDir, _Opts1) ->
    Opts = [
        {output_include_dir, InclDir},
        {output_ebin_dir, OutDir}
    ],
    protobuffs_compile:scan_file(Source, Opts).


-spec format_error(any()) ->  iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).
