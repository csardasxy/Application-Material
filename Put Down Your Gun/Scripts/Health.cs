using UnityEngine;
using System.Collections;

/// <summary>
/// This is the basic class of character, ally and enemy's health.
/// </summary>

public abstract class Health : MonoBehaviour {

    public bool die;

    public abstract void TakeDamege(int damege);

    public abstract void Die();

    public abstract void Disabled();
}
