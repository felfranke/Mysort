function alignGDFsTest()
    gdf1 = [1 100
            2 120
            1 200];

    gdf2 = [1 100
            2 120
            1 200];

    R = mysort.spiketrain.alignGDFs(gdf1, gdf2, 10, 10, 10);