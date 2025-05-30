package au.edu.utas.kit305.tutorial05

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import au.edu.utas.kit305.tutorial05.databinding.MyListActionsBinding
import java.text.SimpleDateFormat
import java.util.*

class MatchHistoryAdapter(private val actions: List<Action>) :
    RecyclerView.Adapter<MatchHistoryAdapter.ViewHolder>() {

    class ViewHolder(val binding: MyListActionsBinding) : RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = MyListActionsBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val action = actions[position]
        val formattedTime = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date(action.timestamp))

        holder.binding.txtActionInfo.text = "${action.player} (${action.team}) - ${action.actionType}"
        holder.binding.txtActionTime.text = "Quarter ${action.quarter} | $formattedTime"
    }

    override fun getItemCount() = actions.size
}
