import SortableColumn from "./sortable-column";

const TopicCell = <template>
  <SortableColumn
    @order="default"
    @category={{@category}}
    @activeOrder={{@activeOrder}}
    @changeSort={{@changeSort}}
    @ascending={{@ascending}}
    @name={{@name}}
    @bulkSelectEnabled={{@bulkSelectEnabled}}
    @showBulkToggle={{@showBulkToggle}}
    @canBulkSelect={{@canBulkSelect}}
    @canDoBulkActions={{@canDoBulkActions}}
    @showTopicsAndRepliesToggle={{@showTopicsAndRepliesToggle}}
    @newListSubset={{@newListSubset}}
    @newRepliesCount={{@newRepliesCount}}
    @newTopicsCount={{@newTopicsCount}}
    @bulkSelectHelper={{@bulkSelectHelper}}
    @changeNewListSubset={{@changeNewListSubset}}
  />
</template>;

export default TopicCell;
