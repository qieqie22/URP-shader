using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightRotate : MonoBehaviour
{
    private Transform lightTrans;
    [Header("Rotate Speed")]
    public float rSpeed = 0.2f;
    void Start()
    {
        lightTrans = transform;
    }

    // Update is called once per frame
    void Update()
    {
        transform.Rotate(new Vector3(0, 1, 0), rSpeed, Space.Self);
    }
}
