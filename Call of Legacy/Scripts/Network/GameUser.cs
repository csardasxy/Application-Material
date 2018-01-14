using UnityEngine;
using System.Collections;
using cn.bmob.io;

public class GameUser : BmobUser {

    public string SaveData { get; set; }
    public BmobInt Level { get; set; }

    public override void write(BmobOutput output, bool all) {
        base.write(output, all);
        output.Put("SaveData", this.SaveData);
        output.Put("Level", this.Level);
    }

    public override void readFields(BmobInput input) {
        base.readFields(input);
        this.SaveData = input.getString("SaveData");
        this.Level = input.getInt("Level");
    }
}
