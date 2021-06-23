-module(borges_tests).

-export([]).

-define(SLEEPTIME, 30).

-include_lib("eunit/include/eunit.hrl").

basic(SpecName) ->
    logger:critical("Running basic test for ~p", [SpecName]),
    % Setup and register
    application:ensure_all_started(borges),
    borges:unregister(SpecName),
    borges:register(SpecName),
    Projects = example_data(3),
    timer:sleep(?SLEEPTIME),

    % Add data to storage
    [borges:put(projects, Project) || Project <- Projects],
    timer:sleep(?SLEEPTIME),

    % Fetch project and check that it exists
    {ok, Project1} = borges:get(projects, 1),
    ?assertMatch(#{project_id := 1}, Project1),

    % Fetch company and user subsets and check that they have the right number of objects
    {ok, CompanySubset} = borges:get_subset(projects, company_projects, 1),
    {ok, User1Subset} = borges:get_subset(projects, user_projects, 1),
    {ok, User2Subset} = borges:get_subset(projects, user_projects, 2),
    ?assertEqual(length(CompanySubset), 2),
    ?assertEqual(sets:size(User1Subset), 1),
    ?assertEqual(sets:size(User2Subset), 2),

    % Delete project 1
    borges:delete(projects, 1),
    timer:sleep(?SLEEPTIME),

    % Check that project 1 is indeed removed
    {ok, Project1Again} = borges:get(projects, 1),
    ?assertMatch(not_found, Project1Again),

    % Check that project 1 is removed from user and company subsets
    {ok, User1SubsetAgain} = borges:get_subset(projects, user_projects, 1),
    {ok, User2SubsetAgain} = borges:get_subset(projects, user_projects, 2),
    {ok, CompanySubsetAgain} = borges:get_subset(projects, company_projects, 1),
    ?assertEqual(length(CompanySubsetAgain), 1),
    ?assertEqual(sets:size(User1SubsetAgain), 0),
    ?assertEqual(sets:size(User2SubsetAgain), 1),
    borges:unregister(SpecName).

basic_test() ->
    basic(ets_example_spec),
    basic(mnesia_example_spec).

update(SpecName) ->
    logger:critical("Running update test for ~p", [SpecName]),
    application:ensure_all_started(borges),
    borges:unregister(SpecName),
    borges:register(SpecName),
    % We should get a project with id 1 and users 1 and 2
    [Project] = example_data(1),

    borges:put(projects, Project),
    timer:sleep(?SLEEPTIME),

    % Fetch project and check that it exists
    {ok, Project1} = borges:get(projects, 1),
    ?assertMatch(#{project_id := 1}, Project1),

    % Fetch company and user subsets and check that they have the right number of objects
    {ok, User1Subset0} = borges:get_subset(projects, user_projects, 1),
    {ok, User2Subset0} = borges:get_subset(projects, user_projects, 2),
    ?assertEqual(sets:size(User1Subset0), 1),
    ?assertEqual(sets:size(User2Subset0), 1),

    % we update the users of project 1
    borges:put(projects, Project#{user_ids => [2, 3]}),
    timer:sleep(?SLEEPTIME),

    % Fetch company and user subsets and check that they have the right number of objects
    {ok, User1Subset} = borges:get_subset(projects, user_projects, 1),
    {ok, User2Subset} = borges:get_subset(projects, user_projects, 2),
    {ok, User3Subset} = borges:get_subset(projects, user_projects, 3),

    % project should be gone for user 1, unchanged for user 2 and added for user 3
    ?assertEqual(sets:size(User1Subset), 0),
    ?assertEqual(sets:size(User2Subset), 1),
    ?assertEqual(sets:size(User3Subset), 1),
    borges:unregister(SpecName).

update_test() ->
    update(ets_example_spec),
    update(mnesia_example_spec).

example_data(Number) ->
    [#{project_id => N,
       user_ids => [N, N + 1],
       company => N rem 2,
       some => <<"some">>,
       other => <<"other">>,
       stuff => <<"stuff">>}
     || N <- lists:seq(1, Number)].
