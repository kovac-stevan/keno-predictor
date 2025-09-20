package com.example.kenopredictor

import android.graphics.Color
import android.os.Bundle
import android.widget.Button
import android.widget.GridLayout
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private val selectedNumbers = mutableSetOf<Int>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val grid = findViewById<GridLayout>(R.id.numberGrid)
        val saveButton = findViewById<Button>(R.id.saveButton)

        for (i in 1..80) {
            val btn = Button(this)
            btn.text = i.toString()
            btn.setBackgroundColor(Color.LTGRAY)

            btn.setOnClickListener {
                if (selectedNumbers.contains(i)) {
                    selectedNumbers.remove(i)
                    btn.setBackgroundColor(Color.LTGRAY)
                } else {
                    selectedNumbers.add(i)
                    btn.setBackgroundColor(Color.GREEN)
                }
            }

            grid.addView(btn)
        }

        saveButton.setOnClickListener {
            if (selectedNumbers.isEmpty()) {
                Toast.makeText(this, "Nijedan broj nije odabran", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this, "Sačuvano: $selectedNumbers", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
