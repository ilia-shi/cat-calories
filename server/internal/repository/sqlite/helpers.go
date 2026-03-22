package sqlite

func isAllowed(profileIDs []int64, id int64) bool {
	for _, pid := range profileIDs {
		if pid == id {
			return true
		}
	}
	return false
}
