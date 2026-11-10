module ReadHFCS

    BASE_FOLDER = dirname(@__DIR__)

    using CSV, DataFrames
    using DataReader    # https://github.com/TavoJGB/DataReader.jl

    include(joinpath(BASE_FOLDER, "src", "dep", "globals.jl"))
    include(joinpath(BASE_FOLDER, "src", "dep", "utils.jl"))
        export get_prev_year, get_wave_gap
    include(joinpath(BASE_FOLDER, "src", "dep", "setup_reader.jl"))
        export read_hfcs

end
