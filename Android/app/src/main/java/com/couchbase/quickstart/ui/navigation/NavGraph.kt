//
// Copyright (c) 2025 Couchbase, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

package com.couchbase.quickstart.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.couchbase.quickstart.data.model.Hotel
import com.couchbase.quickstart.ui.screens.HotelDetailsScreen
import com.couchbase.quickstart.ui.screens.HotelFormScreen
import com.couchbase.quickstart.ui.screens.HotelListScreen

sealed class Screen(val route: String) {
    object HotelList : Screen("hotel_list")
    object HotelDetails : Screen("hotel_details")
    object HotelForm : Screen("hotel_form")
}

@Composable
fun NavGraph() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = Screen.HotelList.route) {
        composable(Screen.HotelList.route) {
            HotelListScreen(
                onHotelClick = { hotel ->
                    navController.currentBackStackEntry?.savedStateHandle?.set("hotel", hotel)
                    navController.navigate(Screen.HotelDetails.route)
                },
                onAddHotel = {
                    navController.currentBackStackEntry?.savedStateHandle?.set("hotel", null as Hotel?)
                    navController.navigate(Screen.HotelForm.route)
                }
            )
        }
        composable(Screen.HotelDetails.route) {
            val hotel = navController.previousBackStackEntry
                ?.savedStateHandle
                ?.get<Hotel>("hotel")
            if (hotel != null) {
                HotelDetailsScreen(
                    hotel = hotel,
                    onBack = { navController.popBackStack() },
                    onEdit = {
                        navController.currentBackStackEntry?.savedStateHandle?.set("hotel", hotel)
                        navController.navigate(Screen.HotelForm.route)
                    }
                )
            }
        }
        composable(Screen.HotelForm.route) {
            val hotel = navController.previousBackStackEntry
                ?.savedStateHandle
                ?.get<Hotel>("hotel")
            HotelFormScreen(
                existingHotel = hotel,
                onBack = { navController.popBackStack() },
                onSaved = { navController.popBackStack(Screen.HotelList.route, false) }
            )
        }
    }
}
