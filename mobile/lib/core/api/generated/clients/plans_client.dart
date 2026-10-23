// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/alternative.dart';
import '../models/day_plan_out.dart';
import '../models/day_view.dart';
import '../models/plan_day_request.dart';
import '../models/plan_item_out.dart';
import '../models/shopping_list.dart';
import '../models/swap_request.dart';

part 'plans_client.g.dart';

@RestApi()
abstract class PlansClient {
  factory PlansClient(Dio dio, {String? baseUrl}) = _PlansClient;

  /// Get Day View.
  ///
  /// Home screen: that day's plan, meal windows, adherence, and water. Breakfast runs from 30 minutes to 2 hours 30 minutes after waking. Lunch and the snack scale a 16-hour awake day (6 to 8 hours, and 9.5 to 10.5 hours). Dinner ends 2 hours 30 minutes before sleep. Windows are empty when the awake span is under 10 hours.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND.
  @GET('/api/v1/days/{date}')
  Future<DayView> getDayView({
    @Path('date') required DateTime date,
  });

  /// List Alternatives.
  ///
  /// Up to 10 meals that can replace this item, nearest in kcal first. kcal_delta is the alternative minus the item. Empty when the item has an active log.
  /// Error codes: UNAUTHORIZED, PLAN_ITEM_NOT_FOUND.
  @GET('/api/v1/plan-items/{plan_item_id}/alternatives')
  Future<List<Alternative>> listAlternatives({
    @Path('plan_item_id') required int planItemId,
  });

  /// Swap Plan Item.
  ///
  /// Replace the item's meal. Writes SWAP_OUT for the old meal with context.replaced_by. SWAP_REJECTED includes reasons.
  /// Error codes: UNAUTHORIZED, PLAN_ITEM_NOT_FOUND, MEAL_NOT_FOUND, SWAP_REJECTED, PLAN_ITEM_ALREADY_LOGGED.
  @POST('/api/v1/plan-items/{plan_item_id}/swap')
  Future<PlanItemOut> swapPlanItem({
    @Path('plan_item_id') required int planItemId,
    @Body() required SwapRequest body,
  });

  /// List Plans.
  ///
  /// The current plan of each day in the inclusive range that has one. Maximum 31 days.
  /// Error codes: UNAUTHORIZED, VALIDATION_ERROR.
  @GET('/api/v1/plans')
  Future<List<DayPlanOut>> listPlans({
    @Query('from') required DateTime from,
    @Query('to') required DateTime to,
  });

  /// Create Plan Day.
  ///
  /// Generate and store that day's plan with the default planner (cpsat). The date must fall on the user's local today minus 1 day through today plus 13 days; anything else is VALIDATION_ERROR. At most 20 generations per user per hour. PLANNER_BUSY is 503 and carries Retry-After. PLANNER_TIMEOUT is 503 when the solver stops without a plan and carries no Retry-After. NOT_ELIGIBLE includes reasons.
  /// Error codes: UNAUTHORIZED, PROFILE_NOT_FOUND, NOT_ELIGIBLE, NO_TARGET, CONDITION_CONFLICT, NO_FEASIBLE_PLAN, PLANNER_BUSY, PLANNER_TIMEOUT, RATE_LIMITED, VALIDATION_ERROR.
  @POST('/api/v1/plans/days')
  Future<DayPlanOut> createPlanDay({
    @Body() required PlanDayRequest body,
  });

  /// Get Shopping List.
  ///
  /// Ingredient grams summed from the current plans in the inclusive range. Optional ingredients are excluded; the meal page lists them. Maximum 31 days.
  /// Error codes: UNAUTHORIZED, VALIDATION_ERROR.
  @GET('/api/v1/shopping-list')
  Future<ShoppingList> getShoppingList({
    @Query('from') required DateTime from,
    @Query('to') required DateTime to,
  });
}
