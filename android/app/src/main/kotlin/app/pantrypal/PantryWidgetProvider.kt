package app.pantrypal

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.util.Calendar
import java.util.GregorianCalendar

/**
 * "Use it up" home-screen widget.
 *
 * The app writes a JSON payload (see lib/services/home_widget_service.dart) with each item's
 * expiry date and pre-translated labels. Days-left is computed here, so the widget is correct
 * after midnight even if the app hasn't run; updatePeriodMillis refreshes it hourly.
 */
class PantryWidgetProvider : HomeWidgetProvider() {

    private data class Row(val name: String, val qty: String, val days: Int, val id: Int, val useOne: Boolean)

    private data class Slot(val row: Int, val name: Int, val days: Int, val use: Int)

    private val slots = listOf(
        Slot(R.id.row1, R.id.row1_name, R.id.row1_days, R.id.row1_use),
        Slot(R.id.row2, R.id.row2_name, R.id.row2_days, R.id.row2_use),
        Slot(R.id.row3, R.id.row3_name, R.id.row3_days, R.id.row3_use),
        Slot(R.id.row4, R.id.row4_name, R.id.row4_days, R.id.row4_use),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = widgetData.getString(DATA_KEY, null)?.let { runCatching { JSONObject(it) }.getOrNull() }
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pantry_widget)
            bind(context, views, payload)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("pantrypal://pantry")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_recipes,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("pantrypal://recipes")),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun bind(context: Context, views: RemoteViews, payload: JSONObject?) {
        if (payload == null) {
            views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_name))
            views.setViewVisibility(R.id.widget_recipes, View.GONE)
            views.setViewVisibility(R.id.widget_summary, View.GONE)
            showEmpty(views, context.getString(R.string.widget_open_app))
            return
        }

        views.setTextViewText(R.id.widget_title, payload.optString("title"))
        views.setTextViewText(R.id.widget_recipes, payload.optString("recipes"))
        views.setViewVisibility(R.id.widget_recipes, View.VISIBLE)

        val soonDays = payload.optInt("soonDays", 3)
        val horizon = payload.optInt("horizonDays", 14)
        val labels = payload.optJSONObject("days")
        val items = payload.optJSONArray("items")
        val rows = mutableListOf<Row>()
        if (items != null) {
            for (i in 0 until items.length()) {
                val o = items.optJSONObject(i) ?: continue
                val d = daysUntil(o.optString("expiry")) ?: continue
                rows += Row(o.optString("name"), o.optString("qty"), d, o.optInt("id", -1), o.optBoolean("useOne", false))
            }
        }
        rows.sortBy { it.days }

        val expired = rows.count { it.days < 0 }
        val soon = rows.count { it.days in 0..soonDays }
        val summary = listOfNotNull(
            if (expired > 0) "${payload.optString("expiredLabel")}: $expired" else null,
            if (soon > 0) "${payload.optString("soonLabel")}: $soon" else null,
        ).joinToString(" · ")
        views.setTextViewText(R.id.widget_summary, summary)
        views.setViewVisibility(R.id.widget_summary, if (summary.isEmpty()) View.GONE else View.VISIBLE)

        val shown = rows.filter { it.days <= horizon }.take(slots.size)
        if (shown.isEmpty()) {
            showEmpty(views, payload.optString("empty"))
            return
        }
        views.setViewVisibility(R.id.widget_empty, View.GONE)
        val usedLabel = payload.optString("usedLabel")
        slots.forEachIndexed { index, slot ->
            val row = shown.getOrNull(index)
            if (row == null) {
                views.setViewVisibility(slot.row, View.GONE)
                return@forEachIndexed
            }
            val (rowId, nameId, daysId, useId) = slot
            views.setViewVisibility(rowId, View.VISIBLE)
            // "Used one" runs in the app's background Dart callback (widget_actions.dart), even
            // with the app closed; the URI is unique per item, so each button gets its own intent.
            if (row.useOne && row.id > 0) {
                views.setViewVisibility(useId, View.VISIBLE)
                views.setOnClickPendingIntent(
                    useId,
                    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("pantrypal://used?id=${row.id}")),
                )
                views.setContentDescription(useId, if (usedLabel.isEmpty()) row.name else "$usedLabel: ${row.name}")
            } else {
                views.setViewVisibility(useId, View.GONE)
            }
            views.setTextViewText(nameId, if (row.qty.isEmpty()) row.name else "${row.name} ${row.qty}")
            val label = if (row.days < 0) payload.optString("expired") else labels?.optString(row.days.toString()) ?: ""
            views.setTextViewText(daysId, label)
            views.setTextColor(daysId, colorFor(context, row.days, soonDays))
        }
    }

    private fun showEmpty(views: RemoteViews, text: String) {
        views.setTextViewText(R.id.widget_empty, text)
        views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
        slots.forEach { views.setViewVisibility(it.row, View.GONE) }
    }

    /** Light or dark variant, picked by Android from res/values(-night)/widget_colors.xml. */
    private fun colorFor(context: Context, days: Int, soonDays: Int): Int = context.getColor(
        when {
            days < 0 -> R.color.widget_expired
            days <= soonDays -> R.color.widget_soon
            else -> R.color.widget_fresh
        },
    )

    /** Calendar days from today to an ISO yyyy-MM-dd date; null if unparseable. */
    private fun daysUntil(iso: String): Int? {
        val p = iso.split("-")
        if (p.size != 3) return null
        val y = p[0].toIntOrNull() ?: return null
        val m = p[1].toIntOrNull() ?: return null
        val d = p[2].toIntOrNull() ?: return null
        val target = GregorianCalendar(y, m - 1, d)
        val today = GregorianCalendar().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        // Rounding absorbs the 23/25-hour days around DST changes.
        return Math.round((target.timeInMillis - today.timeInMillis) / 86_400_000.0).toInt()
    }

    companion object {
        const val DATA_KEY = "pantry_widget" // HomeWidgetService.dataKey
    }
}
