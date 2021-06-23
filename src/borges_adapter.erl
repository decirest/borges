-module(borges_adapter).

-type key() :: term().
-type value() :: term().
-type storage_config() :: borges_spec:storage_config().

-callback fetch(key(), storage_config()) ->
                   {ok, not_found} | {ok, term()} | {error, term()}.
-callback store(key(), value(), storage_config()) -> ok | {error, term()}.
-callback remove(key(), storage_config()) -> ok | {error, term()}.

%-callback keys(storage_config()) -> {ok, [key()]} | {ok, []} | {error, term()}.

-export([remove/2,
         get/2,
         get_subset/3,
         store/3,
         store_subset/4]).

store(ModelName, Input, Term) ->
    KeyFun = borges_spec:get_key_fun(ModelName),
    StoreIdentifier = KeyFun(Input),
    Config = borges_spec:get_storage_config(ModelName),
    internal_store(StoreIdentifier, Term, Config).

store_subset(ModelName, SubsetName, Input, Term) ->
    KeyFun = borges_spec:get_key_fun(ModelName, SubsetName),
    StoreIdentifier = KeyFun(Input),
    Config = borges_spec:get_subset_storage_config(ModelName, SubsetName),
    internal_store(StoreIdentifier, Term, Config).

internal_store(StoreIdentifier, Term, #{storage_adapter := StorageAdapter} = Config) ->
    StorageAdapter:store(StoreIdentifier, Term, Config).

get(ModelName, Input) ->
    KeyFun = borges_spec:get_key_fun(ModelName),
    StoreIdentifier = KeyFun(Input),
    Config = borges_spec:get_storage_config(ModelName),
    internal_get(StoreIdentifier, Config).

get_subset(ModelName, SubsetName, Input) ->
    KeyFun = borges_spec:get_key_fun(ModelName, SubsetName),
    StoreIdentifier = KeyFun(Input),
    Config = borges_spec:get_subset_storage_config(ModelName, SubsetName),
    internal_get(StoreIdentifier, Config).

internal_get(StoreIdentifier, #{storage_adapter := StorageAdapter} = Config) ->
    StorageAdapter:fetch(StoreIdentifier, Config).

remove(ModelName, Input) ->
    KeyFun = borges_spec:get_key_fun(ModelName),
    StoreIdentifier = KeyFun(Input),
    Config = borges_spec:get_storage_config(ModelName),
    internal_remove(StoreIdentifier, Config).

internal_remove(StorageIdentifier, #{storage_adapter := StorageAdapter} = Config) ->
    StorageAdapter:remove(StorageIdentifier, Config).
