module ReadHFCS

    BASE_FOLDER = dirname(@__DIR__)

    using CSV, DataFrames
    using DataReader    # https://github.com/TavoJGB/DataReader.jl

    include(joinpath(BASE_FOLDER, "src", "dep", "utils.jl"))
    include(joinpath(BASE_FOLDER, "src", "dep", "setup_reader.jl"))
    export read_hfcs

end
