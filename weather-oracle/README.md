# Weather Oracle: SUI Move Smart Contract

This directory contains the Move sources for the [Weather Oracle](https://suiexplorer.com/object/0x8a61e975537193d5a3257af8f5eee4703e426b94e54a2ce6a4df79c5e17270d4).

## Usage

Add the weather oracle dependency to your `Move.toml`:

```toml
[package]
name = "..."
version = "..."

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "..." }
oracle = { git = "https://github.com/MystenLabs/apps", subdir = "weather-oracle", rev = "db04fbd17d6ba91ade45c32f609b949fb47d209b" }

[addresses]
...
oracle = "0x8378b3bd39931aa74a6aa3a820304c1109d327426e4275183ed0b797eb6660a8"
```

This will allow you to import the `oracle::weather` module in your move code and use the `WeatherOracle` and its functions. The weather oracle provides real-time weather data for different cities around the world, such as temperature, humidity, wind speed, and air quality. You can use the `city_weather_oracle_temp` function to get the temperature of a city in kelvin multiplied by 1000, given its geoname id. You can find the geoname ids of different cities [here].

For example, to get the temperature of Paris, FR ([2988507](https://suiexplorer.com/object/0x0180c2a6b445194a34b4515340a6f407d1c942a30b16d35a4cca38d61b420ae5)), you can write:

```move
use oracle::weather::{WeatherOracle};

fun get_temp(weather_oracle: &WeatherOracle): u32 {
    let geoname_id = 2988507; // Paris, France
    oracle::weather::city_weather_oracle_temp(weather_oracle, geoname_id)
}
```

You can also use the other functions provided by the weather oracle to get other weather data. For more details, please refer to the [weather oracle documentation](https://github.com/MystenLabs/weather-oracle).
