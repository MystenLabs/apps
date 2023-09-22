// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// This module defines a weather oracle that can post weather updates for major cities around the world.
module oracle::weather {
    use std::option::{Self, Option};
    use std::string::{Self, String};

    use sui::dynamic_object_field as dof;
    use sui::object::{Self, UID};
    use sui::package;
    use sui::transfer::{Self};
    use sui::tx_context::{Self, TxContext};

    /// Define a capability for the admin of the oracle.
    struct AdminCap has key, store { id: UID }

    /// // Define a one-time witness to create the `Publisher` of the oracle.
    struct WEATHER has drop {}

    // Define a struct for the weather oracle
    struct WeatherOracle has key {
        id: UID,
        /// The address of the oracle.
        address: address,
        /// The name of the oracle.
        name: String,
        /// The description of the oracle.
        description: String,
    }

    // Define a struct for each city that the oracle covers
    struct CityWeatherOracle has key, store {
        id: UID,
        geoname_id: u32, // The unique identifier of the city
        name: String, // The name of the city
        country: String, // The country of the city
        latitude: u32, // The latitude of the city in degrees
        positive_latitude: bool, // Whether the latitude is positive (north) or negative (south)
        longitude: u32, // The longitude of the city in degrees
        positive_longitude: bool, // Whether the longitude is positive (east) or negative (west)
        weather_id: u16, // The weather condition code
        temp: u32, // The temperature in kelvin
        pressure: u32, // The atmospheric pressure in hPa
        humidity: u8, // The humidity percentage
        visibility: u16, // The visibility in meters
        wind_speed: u16, // The wind speed in meters per second
        wind_deg: u16, // The wind direction in degrees
        wind_gust: Option<u16>, // The wind gust in meters per second (optional)
        clouds: u8, // The cloudiness percentage
        dt: u32 // The timestamp of the weather update in seconds since epoch
    }

    // Define a struct for a non-fungible token (NFT) that represents a weather conditions for a city.
    struct WeatherNFT has key, store {
        id: UID,
        geoname_id: u32, // The unique identifier of the city
        name: String, // The name of the city
        country: String, // The country of the city
        latitude: u32, // The latitude of the city in degrees
        positive_latitude: bool, // Whether the latitude is positive (north) or negative (south)
        longitude: u32, // The longitude of the city in degrees
        positive_longitude: bool, // Whether the longitude is positive (east) or negative (west)
        weather_id: u16, // The weather condition code
        temp: u32, // The temperature in kelvin
        pressure: u32, // The atmospheric pressure in hPa
        humidity: u8, // The humidity percentage
        visibility: u16, // The visibility in meters
        wind_speed: u16, // The wind speed in meters per second
        wind_deg: u16, // The wind direction in degrees
        wind_gust: Option<u16>, // The wind gust in meters per second (optional)
        clouds: u8, // The cloudiness percentage
        dt: u32 // The timestamp of the weather update in seconds since epoch
    }

    /// Module initializer. Uses One Time Witness to create Publisher and transfer it to sender.
    fun init(otw: WEATHER, ctx: &mut TxContext) {
        package::claim_and_keep(otw, ctx); // Claim ownership of the one-time witness and keep it

        let cap = AdminCap { id: object::new(ctx) }; // Create a new admin capability object
        transfer::share_object(WeatherOracle {
            id: object::new(ctx),
            address: tx_context::sender(ctx),
            name: string::utf8(b"SuiMeteo"),
            description: string::utf8(b"A weather oracle for posting weather updates (temperature, pressure, humidity, visibility, wind metrics and cloud state) for major cities around the world. Currently the data is fetched from https://openweathermap.org. SuiMeteo provides the best available information, but it does not guarantee its accuracy, completeness, reliability, suitability, or availability. Use it at your own risk and discretion."),
        });
        transfer::public_transfer(cap, tx_context::sender(ctx)); // Transfer the admin capability to the sender.
    }

    // Public function for adding a new city to the oracle
    public fun add_city(
        _: &AdminCap, // The admin capability
        oracle: &mut WeatherOracle, // A mutable reference to the oracle object
        geoname_id: u32, // The unique identifier of the city
        name: String, // The name of the city
        country: String, // The country of the city
        latitude: u32, // The latitude of the city in degrees
        positive_latitude: bool, // The whether the latitude is positive (north) or negative (south)
        longitude: u32, // The longitude of the city in degrees
        positive_longitude: bool, // The whether the longitude is positive (east) or negative (west)
        ctx: &mut TxContext // A mutable reference to the transaction context
    ) {
        dof::add(&mut oracle.id, geoname_id, // Add a new dynamic object field to the oracle object with the geoname ID as the key and a new city weather oracle object as the value.
            CityWeatherOracle {
                id: object::new(ctx), // Assign a unique ID to the city weather oracle object 
                geoname_id, // Set the geoname ID of the city weather oracle object
                name,  // Set the name of the city weather oracle object
                country,  // Set the country of the city weather oracle object
                latitude,  // Set the latitude of the city weather oracle object
                positive_latitude,  // Set whether the latitude is positive (north) or negative (south)
                longitude,  // Set the longitude of the city weather oracle object
                positive_longitude,  // Set whether the longitude is positive (east) or negative (west)
                weather_id: 0, // Initialize the weather condition code to be zero 
                temp: 0, // Initialize the temperature to be zero 
                pressure: 0, // Initialize the pressure to be zero 
                humidity: 0, // Initialize the humidity to be zero 
                visibility: 0, // Initialize the visibility to be zero 
                wind_speed: 0, // Initialize the wind speed to be zero 
                wind_deg: 0, // Initialize the wind direction to be zero 
                wind_gust: option::none(), // Initialize the wind gust to be none 
                clouds: 0, // Initialize the cloudiness to be zero 
                dt: 0 // Initialize the timestamp to be zero 
            }
        );
    }

    // Public function for removing an existing city from the oracle
    public fun remove_city(_: &AdminCap, oracle: &mut WeatherOracle, geoname_id: u32) {
        let CityWeatherOracle { id, geoname_id: _, name: _, country: _, latitude: _, positive_latitude: _, longitude: _, positive_longitude: _, weather_id: _, temp: _, pressure: _, humidity: _, visibility: _, wind_speed: _, wind_deg: _, wind_gust: _, clouds: _, dt: _ } = dof::remove(&mut oracle.id, geoname_id);
        object::delete(id);
    }

    // Public function for updating the weather conditions of a city
    public fun update(
        _: &AdminCap,
        oracle: &mut WeatherOracle,
        geoname_id: u32,
        weather_id: u16,
        temp: u32,
        pressure: u32,
        humidity: u8,
        visibility: u16,
        wind_speed: u16,
        wind_deg: u16,
        wind_gust: Option<u16>,
        clouds: u8,
        dt: u32
    ) {
        let city_weather_oracle_mut = dof::borrow_mut<u32, CityWeatherOracle>(&mut oracle.id, geoname_id); // Borrow a mutable reference to the city weather oracle object with the geoname ID as the key
        city_weather_oracle_mut.weather_id = weather_id;
        city_weather_oracle_mut.temp = temp;
        city_weather_oracle_mut.pressure = pressure;
        city_weather_oracle_mut.humidity = humidity;
        city_weather_oracle_mut.visibility = visibility;
        city_weather_oracle_mut.wind_speed = wind_speed;
        city_weather_oracle_mut.wind_deg = wind_deg;
        city_weather_oracle_mut.wind_gust = wind_gust;
        city_weather_oracle_mut.clouds = clouds;
        city_weather_oracle_mut.dt = dt;
    }

    // Define a public function for minting an NFT that represents the current weather conditions of a city.
    public fun mint(
        oracle: &WeatherOracle, 
        geoname_id: u32, 
        ctx: &mut TxContext
    ): WeatherNFT {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&oracle.id, geoname_id); // Borrow a reference to the city weather oracle object with the geoname ID as the key.
        // Return a new weather NFT with the same data as the city weather oracle object 
        WeatherNFT {
            id: object::new(ctx),
            geoname_id: city_weather_oracle.geoname_id,
            name: city_weather_oracle.name,
            country: city_weather_oracle.country,
            latitude: city_weather_oracle.latitude,
            positive_latitude: city_weather_oracle.positive_latitude,
            longitude: city_weather_oracle.longitude,
            positive_longitude: city_weather_oracle.positive_longitude,
            weather_id: city_weather_oracle.weather_id,
            temp: city_weather_oracle.temp,
            pressure: city_weather_oracle.pressure,
            humidity: city_weather_oracle.humidity,
            visibility: city_weather_oracle.visibility,
            wind_speed: city_weather_oracle.wind_speed,
            wind_deg: city_weather_oracle.wind_deg,
            wind_gust: city_weather_oracle.wind_gust,
            clouds: city_weather_oracle.clouds,
            dt: city_weather_oracle.dt
        }
    }

    /// Returns the `geoname_id` of the `CityWeatherOracle`.
    public fun geoname_id(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.geoname_id }
    /// Returns the `name` of the `CityWeatherOracle`.
    public fun name(city_weather_oracle: &CityWeatherOracle): String { city_weather_oracle.name }
    /// Returns the `country` of the `CityWeatherOracle`.
    public fun country(city_weather_oracle: &CityWeatherOracle): String { city_weather_oracle.country }
    /// Returns the `latitude` of the `CityWeatherOracle`.
    public fun latitude(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.latitude }
    /// Returns the `positive_latitude` of the `CityWeatherOracle`.
    public fun positive_latitude(city_weather_oracle: &CityWeatherOracle): bool { city_weather_oracle.positive_latitude }
    /// Returns the `longitude` of the `CityWeatherOracle`.
    public fun longitude(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.longitude }
    /// Returns the `positive_longitude` of the `CityWeatherOracle`.
    public fun positive_longitude(city_weather_oracle: &CityWeatherOracle): bool { city_weather_oracle.positive_longitude }
    /// Returns the `weather_id` of the `CityWeatherOracle`.
    public fun weather_id(city_weather_oracle: &CityWeatherOracle): u16 { city_weather_oracle.weather_id }
    /// Returns the `temp` of the `CityWeatherOracle`.
    public fun temp(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.temp }
    /// Returns the `pressure` of the `CityWeatherOracle`.
    public fun pressure(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.pressure }
    /// Returns the `humidity` of the `CityWeatherOracle`.
    public fun humidity(city_weather_oracle: &CityWeatherOracle): u8 { city_weather_oracle.humidity }
    /// Returns the `visibility` of the `CityWeatherOracle`.
    public fun visibility(city_weather_oracle: &CityWeatherOracle): u16 { city_weather_oracle.visibility }
    /// Returns the `wind_speed` of the `CityWeatherOracle`.
    public fun wind_speed(city_weather_oracle: &CityWeatherOracle): u16 { city_weather_oracle.wind_speed }
    /// Returns the `wind_deg` of the `CityWeatherOracle`.
    public fun wind_deg(city_weather_oracle: &CityWeatherOracle): u16 { city_weather_oracle.wind_deg }
    /// Returns the `wind_gust` of the `CityWeatherOracle`.
    public fun wind_gust(city_weather_oracle: &CityWeatherOracle): Option<u16> { city_weather_oracle.wind_gust }
    /// Returns the `clouds` of the `CityWeatherOracle`.
    public fun clouds(city_weather_oracle: &CityWeatherOracle): u8 { city_weather_oracle.clouds }
    /// Returns the `dt` of the `CityWeatherOracle`.
    public fun dt(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.dt }

    /// Returns the `geoname_id` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_geoname_id(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): u32 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.geoname_id
    }
    /// Returns the `name` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_name(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): String {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.name
    }
    /// Returns the `country` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_country(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): String {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.country
    }
    /// Returns the `latitude` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_latitude(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): u32 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.latitude
    }
    /// Returns the `positive_latitude` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_positive_latitude(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): bool {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.positive_latitude
    }
    /// Returns the `longitude` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_longitude(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): u32 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.longitude
    }
    /// Returns the `positive_longitude` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_positive_longitude(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): bool {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.positive_longitude
    }
    /// Returns the `weather_id` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_weather_id(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): u16 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.weather_id
    }
    /// Returns the `temp` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_temp(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): u32 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.temp
    }
    /// Returns the `pressure` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_pressure(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): u32 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.pressure
    }
    /// Returns the `humidity` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_humidity(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): u8 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.humidity
    }
    /// Returns the `visibility` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_visibility(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): u16 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.visibility
    }
    /// Returns the `wind_speed` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_wind_speed(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): u16 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.wind_speed
    }
    /// Returns the `wind_deg` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_wind_deg(
        weather_oracle: &WeatherOracle, 
        geoname_id: u32
    ): u16 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.wind_deg
    }
    /// Returns the `wind_gust` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_wind_gust(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): Option<u16> {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.wind_gust
    }
    /// Returns the `clouds` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_clouds(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): u8 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.clouds
    }
    /// Returns the `dt` of the `CityWeatherOracle` with the given `geoname_id`.
    public fun city_weather_oracle_dt(
        weather_oracle: &WeatherOracle,
        geoname_id: u32
    ): u32 {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&weather_oracle.id, geoname_id);
        city_weather_oracle.dt
    }

    // This function updates the name of a weather oracle contract.
    // It takes an admin capability, a mutable reference to the weather oracle, and a new name as arguments.
    // It assigns the new name to the weather oracle's name field.
    public fun update_name(_: &AdminCap, weather_oracle: &mut WeatherOracle, name: String) {
        weather_oracle.name = name;
    }

    // This function updates the description of a weather oracle contract.
    // It takes an admin capability, a mutable reference to the weather oracle, and a new description as arguments.
    // It assigns the new description to the weather oracle's description field.
    public fun update_description(_: &AdminCap, weather_oracle: &mut WeatherOracle, description: String) {
        weather_oracle.description = description;
    }
}
