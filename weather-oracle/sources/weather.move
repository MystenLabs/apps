// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module oracle::weather {
    use std::option::{Self, Option};
    use std::string::{Self, String};

    use sui::dynamic_object_field as dof;
    use sui::object::{Self, UID};
    use sui::package;
    use sui::transfer::{Self};
    use sui::tx_context::{Self, TxContext};

    struct AdminCap has key, store { id: UID }

    /// One Time Witness to create the `Publisher`.
    struct WEATHER has drop {}

    struct WeatherOracle has key {
        id: UID,
        /// The address of the oracle.
        address: address,
        /// The name of the oracle.
        name: String,
        /// The description of the oracle.
        description: String,
    }

    struct CityWeatherOracle has key, store {
        id: UID,

        geoname_id: u32,
        name: String,
        country: String,
        latitude: u32,
        positive_latitude: bool,
        longitude: u32,
        positive_longitude: bool,
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
    }

    struct WeatherNFT has key, store {
        id: UID,

        geoname_id: u32,
        name: String,
        country: String,
        latitude: u32,
        positive_latitude: bool,
        longitude: u32,
        positive_longitude: bool,
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
    }

    /// Module initializer. Uses One Time Witness to create Publisher and transfer it to sender.
    fun init(otw: WEATHER, ctx: &mut TxContext) {
        package::claim_and_keep(otw, ctx);

        let cap = AdminCap { id: object::new(ctx) };
        transfer::share_object(WeatherOracle {
            id: object::new(ctx),
            address: tx_context::sender(ctx),
            name: string::utf8(b"SuiMeteo"),
            description: string::utf8(b"A weather oracle for posting weather updates (temperature, pressure, humidity, visibility, wind metrics and cloud state) for major cities around the world. Currently the data is fetched from https://openweathermap.org. SuiMeteo provides the best available information, but it does not guarantee its accuracy, completeness, reliability, suitability, or availability. Use it at your own risk and discretion."),
        });
        transfer::public_transfer(cap, tx_context::sender(ctx));
    }

    public fun add_city(
        _: &AdminCap, 
        oracle: &mut WeatherOracle, 
        geoname_id: u32,
        name: String,
        country: String,
        latitude: u32,
        positive_latitude: bool,
        longitude: u32,
        positive_longitude: bool,
        ctx: &mut TxContext
    ) {
        dof::add(&mut oracle.id, geoname_id, 
            CityWeatherOracle {
                id: object::new(ctx),
                geoname_id,
                name, 
                country, 
                latitude, 
                positive_latitude, 
                longitude, 
                positive_longitude,
                weather_id: 0,
                temp: 0,
                pressure: 0,
                humidity: 0,
                visibility: 0,
                wind_speed: 0,
                wind_deg: 0,
                wind_gust: option::none(),
                clouds: 0,
                dt: 0
            }
        );
    }

    public fun remove_city(_: &AdminCap, oracle: &mut WeatherOracle, geoname_id: u32) {
        let CityWeatherOracle { id, geoname_id: _, name: _, country: _, latitude: _, positive_latitude: _, longitude: _, positive_longitude: _, weather_id: _, temp: _, pressure: _, humidity: _, visibility: _, wind_speed: _, wind_deg: _, wind_gust: _, clouds: _, dt: _ } = dof::remove(&mut oracle.id, geoname_id);
        object::delete(id);
    }

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
        let city_weather_oracle_mut = dof::borrow_mut<u32, CityWeatherOracle>(&mut oracle.id, geoname_id);
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

    public fun mint(
        oracle: &WeatherOracle, 
        geoname_id: u32, 
        ctx: &mut TxContext
    ): WeatherNFT {
        let city_weather_oracle = dof::borrow<u32, CityWeatherOracle>(&oracle.id, geoname_id);
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

    // === Reads ===

    /// Accessor for the `geoname_id` field of the `CityWeatherOracle`.
    public fun geoname_id(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.geoname_id }
    /// Accessor for the `name` field of the `CityWeatherOracle`.
    public fun name(city_weather_oracle: &CityWeatherOracle): String { city_weather_oracle.name }
    /// Accessor for the `country` field of the `CityWeatherOracle`.
    public fun country(city_weather_oracle: &CityWeatherOracle): String { city_weather_oracle.country }
    /// Accessor for the `latitude` field of the `CityWeatherOracle`.
    public fun latitude(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.latitude }
    /// Accessor for the `positive_latitude` field of the `CityWeatherOracle`.
    public fun positive_latitude(city_weather_oracle: &CityWeatherOracle): bool { city_weather_oracle.positive_latitude }
    /// Accessor for the `longitude` field of the `CityWeatherOracle`.
    public fun longitude(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.longitude }
    /// Accessor for the `positive_longitude` field of the `CityWeatherOracle`.
    public fun positive_longitude(city_weather_oracle: &CityWeatherOracle): bool { city_weather_oracle.positive_longitude }
    /// Accessor for the `weather_id` field of the `CityWeatherOracle`.
    public fun weather_id(city_weather_oracle: &CityWeatherOracle): u16 { city_weather_oracle.weather_id }
    /// Accessor for the `temp` field of the `CityWeatherOracle`.
    public fun temp(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.temp }
    /// Accessor for the `pressure` field of the `CityWeatherOracle`.
    public fun pressure(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.pressure }
    /// Accessor for the `humidity` field of the `CityWeatherOracle`.
    public fun humidity(city_weather_oracle: &CityWeatherOracle): u8 { city_weather_oracle.humidity }
    /// Accessor for the `visibility` field of the `CityWeatherOracle`.
    public fun visibility(city_weather_oracle: &CityWeatherOracle): u16 { city_weather_oracle.visibility }
    /// Accessor for the `wind_speed` field of the `CityWeatherOracle`.
    public fun wind_speed(city_weather_oracle: &CityWeatherOracle): u16 { city_weather_oracle.wind_speed }
    /// Accessor for the `wind_deg` field of the `CityWeatherOracle`.
    public fun wind_deg(city_weather_oracle: &CityWeatherOracle): u16 { city_weather_oracle.wind_deg }
    /// Accessor for the `wind_gust` field of the `CityWeatherOracle`.
    public fun wind_gust(city_weather_oracle: &CityWeatherOracle): Option<u16> { city_weather_oracle.wind_gust }
    /// Accessor for the `clouds` field of the `CityWeatherOracle`.
    public fun clouds(city_weather_oracle: &CityWeatherOracle): u8 { city_weather_oracle.clouds }
    /// Accessor for the `dt` field of the `CityWeatherOracle`.
    public fun dt(city_weather_oracle: &CityWeatherOracle): u32 { city_weather_oracle.dt }


    // === Updated ===
    public fun update_name(_: &AdminCap, weather_oracle: &mut WeatherOracle, name: String) {
        weather_oracle.name = name;
    }
    public fun update_description(_: &AdminCap, weather_oracle: &mut WeatherOracle, description: String) {
        weather_oracle.description = description;
    }
}
