-module(ets_example_spec).

-behaviour(borges_spec).

-export([name/0,
         init/0,
         terminate/0,
         storage_identifier/1,
         main_storage/0,
         subsets/0]).

%% TODO: This could be called "Model"

name() -> projects.

init() ->
    ets:new(user_projects, [set, named_table, public]),
    ets:new(company_projects, [set, named_table, public]),
    ets:new(projects, [set, named_table, public]).

terminate() ->
    [delete_ets_table(TableName) || TableName <- [user_projects, company_projects, projects]].

delete_ets_table(Name) ->
    case ets:whereis(Name) of
        undefined -> ok;
        Tid -> ets:delete(Tid)
    end.

subsets() ->
    [#{name => company_projects,
       is_related => fun is_project/1,
       data_prep => fun prep_project/1,
       subset_keys_fun => fun company_project_key_gen/1,
       extend => fun add_to_list/2,
       reduce => fun remove_from_list/2,
       storage_config =>
           #{key_fun => fun get_company_project_key/1,
             storage_adapter => borges_ets_adapter,
             storage_adapter_config =>
                 #{name => company_projects,
                   options => [set, named_table, public]}}},
     #{name => user_projects,
       is_related => fun is_user_project/1,
       data_prep => fun prep_project/1,
       subset_keys_fun => fun user_project_key_gen/1,
       storage_config =>
           #{key_fun => fun get_user_project_key/1,
             storage_adapter => borges_ets_adapter,
             storage_adapter_config =>
                 #{name => user_projects,
                   options => [set, named_table, public]}}}].

main_storage() ->
    #{key_fun => fun storage_identifier_to_key/1,
      storage_adapter => borges_ets_adapter,
      storage_adapter_config =>
          #{name => projects,
            options => [set, named_table, public]}}.

is_project(#{project_id := _}) -> true;
is_project(_) -> false.

is_user_project(#{user_ids := UIDs} = P) ->
    HasUsers = length(UIDs) > 0,
    HasUsers and is_project(P);
is_user_project(_) -> false.

prep_project(P) -> maps:with([project_id, user_ids, company], P).

company_project_key_gen(#{company := N}) -> [N].

user_project_key_gen(#{user_ids := L}) -> L.

get_user_project_key(N) ->
    BinN = integer_to_binary(N),
    <<"user_", BinN/binary, "_projects">>.

get_company_project_key(N) ->
    BinN = integer_to_binary(N),
    <<"company_", BinN/binary, "_projects">>.


add_to_list(not_found, Data) ->
    [Data];
add_to_list(List, Data) ->
    [Data|List].

remove_from_list(not_found, Data) ->
    [];
remove_from_list(List, Data) ->
    remove_subset_obj(Data, List).

remove_subset_obj(_Data, []) -> [];
remove_subset_obj(#{project_id := ProjectID}, [#{project_id := ProjectID} | Rest]) ->
    Rest;
remove_subset_obj(Data, [D | Rest]) -> [D | remove_subset_obj(Data, Rest)].

storage_identifier_to_key(N) ->
    BinN = integer_to_binary(N),
    <<"project_", BinN/binary>>.

storage_identifier(#{project_id := N}) -> N.
