using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class move : MonoBehaviour {

    public Rigidbody rigid;
    public float moveSpeed = 5.0f;

	// Use this for initialization
	void Start () {
        rigid = GetComponent<Rigidbody>();
	}
	
	// Update is called once per frame
	void Update () {
        float h = Input.GetAxis("Horizontal");
        float v = Input.GetAxis("Vertical");
        rigid.velocity = new Vector3(h, v, 0).normalized * moveSpeed;
	}
}
