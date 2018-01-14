using cn.bmob.io;
using UnityEngine;

/// <summary>
/// Danmaku and properties related
/// </summary>

public class Danmaku : BmobTable {

    public string Content { get; set; }
    public string UserId { get; set; }
    public BmobInt Level { get; set; }
    public BmobDouble X { get; set; }
    public BmobDouble Y { get; set; }
    public BmobDouble Z { get; set; }
    public BmobDouble ColorR { get; set; }
    public BmobDouble ColorG { get; set; }
    public BmobDouble ColorB { get; set; }
    public BmobInt FontSize { get; set; }

    public override void readFields(BmobInput input) {
        base.readFields(input);

        Content = input.getString("Content");
        UserId = input.getString("UserId");
        Level = input.getInt("Level");
        X = input.getDouble("X");
        Y = input.getDouble("Y");
        Z = input.getDouble("Z");
        ColorR = input.getDouble("ColorR");
        ColorG = input.getDouble("ColorG");
        ColorB = input.getDouble("ColorB");
        FontSize = input.getInt("FontSize");
    }

    public override void write(BmobOutput output, bool all) {
        base.write(output, all);

        output.Put("Content", Content);
        output.Put("UserId", UserId);
        output.Put("Level", Level);
        output.Put("X", X);
        output.Put("Y", Y);
        output.Put("Z", Z);
        output.Put("ColorG", ColorG);
        output.Put("ColorR", ColorR);
        output.Put("ColorB", ColorB);
        output.Put("FontSize", FontSize);
    }
}
